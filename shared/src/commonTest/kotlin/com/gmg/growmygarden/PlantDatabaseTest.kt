package com.gmg.growmygarden

import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.data.source.PlantRepository
import com.rickclephas.kmp.nativecoroutines.NativeCoroutinesIgnore
import di.dataModule
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.test.runTest
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.test.KoinTest
import org.koin.test.inject
import kotlin.test.Test
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.hours
import kotlin.test.assertNotNull


class PlantDatabaseTest : KoinTest {
    val examplePlants: List<Plant> = listOf(
        Plant(
            "Plant1", species = "Ivy", wateringFrequency = 1.days, fertilizingFrequency = 7.days + 5.hours
        ),

        Plant(
            "Plant2", species = "Plant", wateringFrequency = 4.days, fertilizingFrequency = 3.5.days
        ),

        Plant(
            "Plant3", species = "Plant", wateringFrequency = 4.days, fertilizingFrequency = 3.5.days
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

    @Test
    fun testDatabaseInsert() = runTest {
        plantRepository.savePlant(
            examplePlants.first()
        )
        val plants = plantRepository.plants
        compareDatabaseContents(plants, examplePlants)
    }

    @Test
    fun testDatabaseMultiInsert() = runTest {
        plantRepository.savePlants(
            *examplePlants.slice(0..1).toTypedArray()
        )
        compareDatabaseContents(plantRepository.plants, examplePlants)
    }

    @Test
    fun testDatabaseDelete() = runTest {
        plantRepository.savePlant(examplePlants.first())
        plantRepository.delete(examplePlants.first())
        assertFalse {
            examplePlants.first() in plantRepository
        }
    }

    @Test
    fun testDatabseUpdate() = runTest {
        val SPECIES_UPDATED_VALUE = "Poison Oak"
        val normalPlant = examplePlants.first()
        val updatedPlant = normalPlant.copy(species = SPECIES_UPDATED_VALUE)
        plantRepository.savePlant(normalPlant)
        compareDatabaseContents(plantRepository.plants, normalPlant)
        plantRepository.savePlant(normalPlant)
        compareDatabaseContents(plantRepository.plants, updatedPlant)
    }


    @AfterTest
    fun cleanup() {
        stopKoin()
    }
}