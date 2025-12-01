@file:OptIn(ExperimentalUuidApi::class)
@file:Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")

package com.gmg.growmygarden

import com.gmg.growmygarden.auth.UserManager
import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.data.source.PlantRepository
import com.gmg.growmygarden.di.userModule
import com.gmg.growmygarden.viewmodel.LoginViewModel
import com.rickclephas.kmp.nativecoroutines.NativeCoroutinesIgnore
import kotbase.Meta
import kotbase.ReplicatorActivityLevel
import kotbase.ReplicatorConfiguration
import kotbase.ReplicatorType
import kotbase.URLEndpoint
import kotbase.ktx.from
import kotbase.ktx.select
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.core.module.dsl.factoryOf
import org.koin.dsl.module
import org.koin.test.KoinTest
import org.koin.test.inject
import kotlin.io.encoding.Base64
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.uuid.ExperimentalUuidApi

fun decodeCapellaCerts(): ByteArray = ENDPOINT_CERT.lineSequence().filterNot {
    it.startsWith("-----") || it.isBlank()
}.joinToString("").let {
    Base64.decode(it)
}

class TestPlantRepository(dbProvider: DatabaseProvider, userManager: UserManager, syncEndpoint: String) :
    PlantRepository(
        dbProvider,
        userManager,
        syncEndpoint,
        ReplicatorConfiguration(
            URLEndpoint(syncEndpoint),
        ).apply {
            pinnedServerCertificate = decodeCapellaCerts()
            isContinuous = true
            type = ReplicatorType.PUSH_AND_PULL
            isAutoPurgeEnabled = false
        },
    ) {
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

    val isPending: Boolean
        get() = replicator.getPendingDocumentIds(collection).isNotEmpty()
}

@ExperimentalCoroutinesApi
class PlantDatabaseTest : KoinTest {
    val examplePlants: List<Plant> = listOf(
        Plant(
            name = "Plant1",
            species = "Ivy",
            wateringFrequency = 1.days,
            fertilizingFrequency = 7.days + 5.hours,
        ),

        Plant(
            name = "Plant2",
            species = "Plant",
            wateringFrequency = 4.days,
            fertilizingFrequency = 3.5.days,
        ),

        Plant(
            name = "Plant3",
            species = "Plant",
            wateringFrequency = 4.days,
            fertilizingFrequency = 3.5.days,
        ),
    )

    val plantRepository: TestPlantRepository by inject()

    val dispatcher = StandardTestDispatcher()

    @BeforeTest
    fun setup() {
        startKoin {
//            modules(dataModule)
            modules(
                module {
                    properties(mapOf("SYNC_ENDPOINT" to SYNC_ENDPOINT))
                    includes(userModule)
                    single { DatabaseProvider(dispatcher = dispatcher) }
                    single { TestPlantRepository(get(), get(), getProperty("SYNC_ENDPOINT")) }
                    factoryOf(::LoginViewModel)
                },
            )
        }
        assertNotNull(plantRepository)
    }

    @Test
    fun testDatabaseInsert() = runTest(dispatcher) {
        plantRepository.savePlant(
            examplePlants.first(),
        )

        advanceTimeBy(300.milliseconds)
        advanceUntilIdle()

        val plants = plantRepository.plants.first { it.isNotEmpty() }
        assertEquals(examplePlants.first(), plants.first(), "Database Returned Bad Plant")
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
        val normalPlant = examplePlants.first()
        val updatedPlant = normalPlant.copy(species = SPECIES_UPDATED_VALUE)
        assertEquals(normalPlant.uuid, updatedPlant.uuid, "UUIDs not equal")
        val uuid = normalPlant.uuid
        plantRepository.savePlant(normalPlant)
        advanceTimeBy(500.milliseconds)
        advanceUntilIdle()
        assertEquals(normalPlant, plantRepository.getPlant(uuid), "Plant failed to insert")
        plantRepository.savePlant(updatedPlant)
        advanceTimeBy(500.milliseconds)
        advanceUntilIdle()
        assertEquals(updatedPlant, plantRepository.getPlant(uuid), "Plant failed to update")
        plantRepository.clearDatabase()
    }

    @Test
    fun testDatabaseInsertLoggedIn() = runTest(dispatcher) {
        val loginViewModel: LoginViewModel by inject()
        val userManger: UserManager by inject()
        loginViewModel.login(TEST_USER_ID)

        assertNotNull(userManger.user, "No User After Login")

        plantRepository.savePlant(
            examplePlants.first(),
        )

        advanceTimeBy(300.milliseconds)
        advanceUntilIdle()

        delay(250.milliseconds)

        assertTrue(
            plantRepository.replicator.status.let {
                val activity = it.activityLevel
                activity != ReplicatorActivityLevel.OFFLINE && activity != ReplicatorActivityLevel.STOPPED
            },
            "Bad Replicator Activity",
        )

        while (plantRepository.isPending || plantRepository.replicator.status.activityLevel == ReplicatorActivityLevel.BUSY) {
            delay(50.milliseconds)
        }

        assertTrue(
            plantRepository.replicator.status.let {
                val activity = it.activityLevel
                activity == ReplicatorActivityLevel.IDLE
            },
            "Bad Replicator Activity",
        )
    }

    @AfterTest
    fun cleanup() {
        stopKoin()
    }

    companion object {
        const val SPECIES_UPDATED_VALUE = "Poison Oak"
    }
}
