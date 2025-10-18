package com.gmg.growmygarden

import io.realm.kotlin.ext.query
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration.Companion.days
import io.realm.kotlin.Realm
import io.realm.kotlin.RealmConfiguration
import kotlin.test.AfterTest
import kotlin.test.assertNotNull

class PlantDatabaseTest {
    private val realm: Realm = RealmConfiguration.Builder(schema = setOf(Plant::class))
            .inMemory()
            .build()
            .let { Realm.open(it) }


    @AfterTest
    fun cleanup() {
        realm.close()
    }

    @Test
    fun testInsertPlant() {
        val plant: Plant = Plant("Planty", "plant", 3.days)
        realm.writeBlocking {
            copyToRealm(plant)
        }

        val result = realm.query<Plant>().find().firstOrNull()
        assertNotNull(result, "No Plants in Database")
        assertEquals(plant, result, "Plant in database, not consistent with added Plant")
    }

}