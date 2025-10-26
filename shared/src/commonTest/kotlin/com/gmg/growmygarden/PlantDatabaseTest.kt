@file:OptIn(ExperimentalUuidApi::class)

package com.gmg.growmygarden

import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.data.source.PlantRepository
import com.rickclephas.kmp.nativecoroutines.NativeCoroutinesIgnore
import di.dataModule
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.toCollection
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runTest
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.test.KoinTest
import org.koin.test.inject
import kotlin.experimental.ExperimentalNativeApi
import kotlin.test.Test
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.hours
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.uuid.ExperimentalUuidApi


class PlantDatabaseTest : KoinTest {
    val examplePlants: List<Plant> = listOf(
        Plant(
            name = "Plant1", species = "Ivy", wateringFrequency = 1.days, fertilizingFrequency = 7.days + 5.hours
        ),

        Plant(
            name = "Plant2", species = "Plant", wateringFrequency = 4.days, fertilizingFrequency = 3.5.days
        ),

        Plant(
            name = "Plant3", species = "Plant", wateringFrequency = 4.days, fertilizingFrequency = 3.5.days
        )
    )

    val plantRepository: PlantRepository by inject()

    @BeforeTest
    fun setup() {
        startKoin {
            modules(dataModule)
        }
        assertNotNull(plantRepository)
    }

    @NativeCoroutinesIgnore
    suspend fun compareDatabaseContents(plants: Flow<List<Plant>>, against: List<Plant>) {
        plants.collect { results ->
            assertNotNull(results, "Database Read Returned Null")
            for (index in results.indices) {
                assertEquals(results[index], examplePlants[index], "Plants were not equal")
            }
        }
    }

    @NativeCoroutinesIgnore
    suspend fun compareDatabaseContents(plants: Flow<List<Plant>>, vararg against: Plant) {
        plants.collect { results ->
            assertNotNull(results, "Database Read Returned Null")
            for (index in results.indices) {
                assertEquals(results[index], examplePlants[index], "Plants were not equal")
            }
        }
    }

    @OptIn(ExperimentalNativeApi::class)
    @Test
    fun testDatabaseInsert() = runTest {
        plantRepository.savePlant(
            examplePlants.first()
        )
        println('1')
        val plants = plantRepository.plants
        println('2')
        delay(300.milliseconds)
        println('3')
        val results = plants.toList().first()
        println('4')
        assert(examplePlants.first() in plantRepository) { "Plant Not Found in Database | Plants: $results" }
        println('5')
        assertEquals(results.first(), examplePlants.first(), "Database Returned Bad Plant")
    }

    @Test
    fun testDatabaseMultiInsert() = runTest {
        plantRepository.savePlants(
            *examplePlants.slice(0..1).toTypedArray()
        )
        delay(300.milliseconds)
        val results = plantRepository.plants.toList().first()
        assert(examplePlants[0] in plantRepository) { "Plant 1 Not Found in Database | Plants: $results" }
        assert(examplePlants[1] in plantRepository) { "Plant 2 Not Found in Database | Plants: $results" }
        for (plant in results) {
            plantRepository.delete(plant)
        }
    }

    @Test
    fun testDatabaseDelete() = runTest {
        plantRepository.savePlant(examplePlants.first())
        delay(300.milliseconds)
        plantRepository.delete(examplePlants.first())
        assertFalse("Database Failed to Delete Plant 1") {
            examplePlants.first() in plantRepository
        }
        val results = plantRepository.plants.toList().first()
        for (plant in results) {
            plantRepository.delete(plant)
        }
    }


    @Test
    fun testDatabaseUpdate() = runTest {
        plantRepository.plants.collect {
            assert(it.isEmpty()) { "Database is Not Empty: $it" }
        }
        val SPECIES_UPDATED_VALUE = "Poison Oak"
        val normalPlant = examplePlants.first()
        val updatedPlant = normalPlant.copy(species = SPECIES_UPDATED_VALUE)
        println(normalPlant)
        println(updatedPlant)
        plantRepository.savePlant(normalPlant)
        delay(300.milliseconds)
        compareDatabaseContents(plantRepository.plants, normalPlant)
        plantRepository.savePlant(normalPlant)
        delay(300.milliseconds)
        compareDatabaseContents(plantRepository.plants, updatedPlant)
    }


    @AfterTest
    fun cleanup() {
        stopKoin()
    }
}