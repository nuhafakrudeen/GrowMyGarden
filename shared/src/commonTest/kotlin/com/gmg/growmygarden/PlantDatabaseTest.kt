@file:OptIn(ExperimentalUuidApi::class) @file:Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")

package com.gmg.growmygarden

import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.data.source.PlantRepository
import com.rickclephas.kmp.nativecoroutines.NativeCoroutinesIgnore
import kotbase.Meta
import kotbase.ktx.select
import kotbase.ktx.from
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.advanceUntilIdle
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
import kotlin.time.Duration.Companion.milliseconds
import kotlin.uuid.ExperimentalUuidApi
import org.koin.dsl.module
import kotlin.time.Duration.Companion.seconds

class TestPlantRepository(dbProvider: DatabaseProvider) : PlantRepository(dbProvider) {
    fun clearDatabase() {
        (select(Meta.id) from this.collection).execute().use { results ->
            results.allResults().forEach { result ->
                val id = result.getString(0)
                if (id != null) {
                    collection.purge(id)
                }


            }
        }
    }

    @NativeCoroutinesIgnore
    suspend operator fun contains(plant: Plant): Boolean {
        return this.getPlant(plant.uuid) != null
    }
}

@ExperimentalCoroutinesApi
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

    val plantRepository: TestPlantRepository by inject()

    val dispatcher = StandardTestDispatcher()

    @BeforeTest
    fun setup() {
        startKoin {
//            modules(dataModule)
            modules(
                module {
                    single { DatabaseProvider(dispatcher = dispatcher) }
                    single { TestPlantRepository(get()) }
                })
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
        plants.first().forEachIndexed { index, plant ->
            assertEquals(plant, examplePlants[index], "Plants were not equal")
        }
    }

    @Test
    fun testDatabaseInsert() = runTest(dispatcher) {
        plantRepository.savePlant(
            examplePlants.first()
        )

        advanceTimeBy(300.milliseconds)
        advanceUntilIdle()

        val plants = plantRepository.plants.first { it.isNotEmpty() }
        assertEquals(plants.first(), examplePlants.first(), "Database Returned Bad Plant")
        plantRepository.clearDatabase()
    }

    @Test
    fun testDatabaseMultiInsert() = runTest(dispatcher) {
        plantRepository.savePlant(examplePlants[0])
        advanceTimeBy(1.seconds)
        plantRepository.savePlant(examplePlants[1])
        advanceUntilIdle()
        assert(examplePlants[0] in plantRepository) { "Plant 1 Not Found in Database" }
        assert(examplePlants[1] in plantRepository) { "Plant 2 Not Found in Database" }
        plantRepository.clearDatabase()
    }

    @Test
    fun testDatabaseDelete() = runTest(dispatcher) {
        plantRepository.savePlant(examplePlants.first())
        advanceTimeBy(500.milliseconds)
        advanceUntilIdle()
        plantRepository.delete(examplePlants.first())
        advanceTimeBy(500.milliseconds)
        advanceUntilIdle()
        assertFalse("Database Failed to Delete Plant 1") {
            examplePlants.first() in plantRepository
        }
        val results = plantRepository.plants.first()
        plantRepository.clearDatabase()
    }


    @Test
    fun testDatabaseUpdate() = runTest(dispatcher) {
        val SPECIES_UPDATED_VALUE = "Poison Oak"
        val normalPlant = examplePlants.first()
        val updatedPlant = normalPlant.copy(species = SPECIES_UPDATED_VALUE)
        assertEquals(normalPlant.uuid, updatedPlant.uuid, "UUIDs not equal")
        val uuid = normalPlant.uuid
        plantRepository.savePlant(normalPlant)
        advanceTimeBy(500.milliseconds)
        advanceUntilIdle()
        assertEquals(plantRepository.getPlant(uuid), normalPlant, "Plant failed to insert")
        plantRepository.savePlant(normalPlant)
        advanceTimeBy(500.milliseconds)
        advanceUntilIdle()
        assertEquals(plantRepository.getPlant(uuid), updatedPlant, "Plant failed to update")
        plantRepository.clearDatabase()
    }


    @AfterTest
    fun cleanup() {
        stopKoin()
    }
}