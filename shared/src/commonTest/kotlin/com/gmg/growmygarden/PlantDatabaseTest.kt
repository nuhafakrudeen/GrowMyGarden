package com.gmg.growmygarden

import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.data.source.Plant
import di.dataModule
import kotbase.Database
import org.koin.core.context.startKoin
import org.koin.test.KoinTest
import org.koin.test.inject
import kotlin.test.Test
import kotlin.test.BeforeClass
import kotlin.test.AfterClass
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.hours
import kotlin.test.assertNotNull


class PlantDatabaseTest : KoinTest {
    val examplePlants: List<Plant> = listOf(
        Plant(
            "Plant1",
            species = "Ivy",
            wateringFrequency = 1.days,
            fertilizingFrequency = 7.days + 5.hours
        ),

        Plant(
            "Plant2",
            species = "Plant",
            wateringFrequency = 4.days,
            fertilizingFrequency = 3.5.days
        ),

        Plant(
            "Plant3",
            species = "Plant",
            wateringFrequency = 4.days,
            fertilizingFrequency = 3.5.days
        )
    )

    val dbProvider: DatabaseProvider by inject()
    lateinit var database: Database

    @BeforeClass
    fun startKoin() {
        startKoin {
            modules(dataModule)
        }
        assertNotNull(dbProvider)
        database = dbProvider.database
        assertNotNull(database)
    }

    @Test
    fun testDatabase() {

    }

    @AfterClass
    fun stopKoin() {
        startKoin()
    }
}