package com.gmg.growmygarden

import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.data.source.PlantRepository
import di.dataModule
import kotbase.Database
import kotlinx.coroutines.CoroutineName
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.test.KoinTest
import org.koin.test.inject
import kotlin.test.Test
import kotlin.test.BeforeClass
import kotlin.test.AfterClass
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.assertEquals
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.hours
import kotlin.test.assertNotNull
import kotlin.time.Duration.Companion.milliseconds


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

    suspend fun testPlantDatabase(plants: Flow<List<Plant>>) {
        plants.collect { results ->
            assertNotNull(results, "Database Read Returned Null")
            assertEquals(results.first(), examplePlants.first(), "Plants were not equal")
        }

    }

    @Test
    fun testDatabase() = runTest {
        plantRepository.savePlant(
            examplePlants.first()
        )
        println("Successfully Saved Plant")
        val plants = plantRepository.plants
    }

    @AfterTest
    fun cleanup() {
        stopKoin()
    }
}