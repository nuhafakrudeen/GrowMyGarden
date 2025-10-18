package com.gmg.growmygarden

import io.realm.kotlin.ext.query
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration
import kotlin.time.Duration.Companion.days
import kotlin.time.DurationUnit

class PlantDatabaseTest {

    @Test
    fun testInsertPlant() {
        val plant: Plant = Plant("Planty", "plant", 3.days)
        val realm = Database.getRealm()
        realm.writeBlocking {
            copyToRealm(plant)
        }

        val result = realm.query<Plant>().find().firstOrNull()!!
        assertEquals(plant, result)
    }

}