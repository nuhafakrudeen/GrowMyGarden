@file:OptIn(ExperimentalUuidApi::class)

package com.gmg.growmygarden

import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.data.source.PlantRepository
import com.rickclephas.kmp.nativecoroutines.NativeCoroutinesIgnore
import di.dataModule
import kotbase.ktx.all
import kotbase.ktx.asObjectsFlow
import kotbase.ktx.from
import kotbase.ktx.orderBy
import kotbase.ktx.select
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.toCollection
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
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
import org.koin.dsl.module
import org.koin.core.module.dsl.singleOf
import kotlin.time.Duration
import kotlin.uuid.Uuid

class TestPlantRepository(dbProvider: DatabaseProvider) : PlantRepository(dbProvider) {
    @Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")
    val plantsBlocking: List<Plant>
        get() {
            val query = select(all()) from super.collection orderBy { "name".descending() }
            return query.execute().let { rs ->
                rs.map {
                    val json = it.toJSON()
                    Json.decodeFromString<Plant>(Json.decodeFromString<JsonObject>(json)["plants"].toString())
//                   Plant(
//                       uuid = Uuid.parse(mapFromJson["uuid"].toString()),
//                       name = mapFromJson["name"].toString(),
//                       species = mapFromJson["species"].toString(),
//                       scientificName = mapFromJson["scientificName"].toString(),
//                       wateringFrequency = Duration.parse(mapFromJson["wateringFrequency"])
//
//                   )
                }
            }
        }
}

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

    @BeforeTest
    fun setup() {
        startKoin {
            modules(
                module {
                    single { DatabaseProvider() }
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
        delay(500.milliseconds)
        val plants = plantRepository.plantsBlocking
        assert(plants.isNotEmpty()) {"Database Returned No Entries"}
        println(plants)
//        assert(examplePlants.first() in plantRepository) { "Plant Not Found in Database" }

        assertEquals(plants.first(), examplePlants.first(), "Database Returned Bad Plant")
    }

    @Test
    fun testDatabaseMultiInsert() = runTest {
        plantRepository.savePlants(
            *examplePlants.slice(0..1).toTypedArray()
        )
        delay(500.milliseconds)
        val plants = plantRepository.plantsBlocking
        assert(plants.isNotEmpty()) {"Database Returned No Entries"}
        assert(examplePlants[0] in plantRepository) { "Plant 1 Not Found in Database" }
        assert(examplePlants[1] in plantRepository) { "Plant 2 Not Found in Database" }
        for (plant in plantRepository.plantsBlocking) {
            plantRepository.delete(plant)
        }
    }

    @Test
    fun testDatabaseDelete() = runTest {
        plantRepository.savePlant(examplePlants.first())
        delay(500.milliseconds)
        val plants = plantRepository.plantsBlocking
        assert(plants.isNotEmpty()) {"Database Returned No Entries"}
        plantRepository.delete(examplePlants.first())
        assertFalse("Database Failed to Delete Plant 1") {
            examplePlants.first() in plantRepository
        }
        val results = plantRepository.plantsBlocking
        for (plant in results) {
            plantRepository.delete(plant)
        }
    }


    @Test
    fun testDatabaseUpdate() = runTest {
        assert(plantRepository.plantsBlocking.isEmpty()) { "Database is Not Empty" }
        val SPECIES_UPDATED_VALUE = "Poison Oak"
        val normalPlant = examplePlants.first()
        val updatedPlant = normalPlant.copy(species = SPECIES_UPDATED_VALUE)
        println(normalPlant)
        println(updatedPlant)
        plantRepository.savePlant(normalPlant)
        delay(500.milliseconds)
        compareDatabaseContents(plantRepository.plants, normalPlant)
        plantRepository.savePlant(normalPlant)
        delay(500.milliseconds)
        compareDatabaseContents(plantRepository.plants, updatedPlant)
    }


    @AfterTest
    fun cleanup() {
        stopKoin()
    }
}