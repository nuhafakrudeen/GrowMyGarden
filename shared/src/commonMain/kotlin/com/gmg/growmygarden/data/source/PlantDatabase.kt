@file:OptIn(ExperimentalUuidApi::class)

package com.gmg.growmygarden.data.source

import com.gmg.growmygarden.data.db.DatabaseProvider
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines
import kotbase.MutableDocument
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.Serializable
import kotlin.time.Duration
import kotbase.ktx.select
import kotbase.ktx.from
import kotbase.ktx.orderBy
import kotbase.ktx.asObjectsFlow
import kotbase.ktx.all
import kotbase.ktx.where
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlin.String
import kotlin.time.Duration.Companion.milliseconds
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

/**
 * name of plant (users choice)
 * scientific name of the plant -> for dashboard
 * species of the plant (for the plantbook)
 * how much and how often to water the plant
 * */
@Serializable
data class Plant(
    val uuid: Uuid = Uuid.random(),
    val name: String = "",
    val scientificName: String = "",
    val species: String = "",
    val wateringFrequency: Duration = Duration.ZERO,
    val fertilizingFrequency: Duration = Duration.ZERO,

    )

@Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")
class PlantRepository(
    private val dbProvider: DatabaseProvider
) {
    @Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")
    private val collection
        get() = dbProvider.database.defaultCollection

    @NativeCoroutines
    val plants: Flow<List<Plant>>
        get() {
            val query = select(all()) from collection orderBy { "name".descending() }
            return query.asObjectsFlow { json: String ->
                Json.decodeFromString<Plant>(json)
            }
        }


    private val saveChannel = Channel<Plant>(Channel.CONFLATED)
    fun savePlant(plant: Plant) {
        saveChannel.trySend(plant)
    }

    @NativeCoroutines
    suspend fun savePlants(vararg plants: Plant) {
        for (plant in plants) {
            savePlant(plant)
            delay(debounceTime + 10.milliseconds)
        }
    }

    operator fun contains(plant: Plant): Boolean {
        val query = select(all()) from collection where {
            "uuid" equalTo plant.uuid.toHexDashString()
        }
        println((select(all()) from collection).execute().allResults())
        return query.execute().allResults().isNotEmpty()
    }

    init {
        @OptIn(FlowPreview::class)
        saveChannel.receiveAsFlow()
            .debounce(debounceTime)
            .onEach { plant ->
                val coll = collection
                val doc = coll.getDocument(plant.name)
                    ?.let(::decodeDocument)
                    ?: PlantDoc()
                val updated = doc.copy(
                    uuid = plant.uuid,
                    name = plant.name,
                    scientificName = plant.scientificName,
                    species = plant.species,
                    wateringFrequency = plant.wateringFrequency,
                    fertilizingFrequency = plant.fertilizingFrequency,
                )
                val json = Json.encodeToString(updated)
                val mutableDoc = MutableDocument(plant.name, json)
                coll.save(mutableDoc)

            }
            .launchIn(dbProvider.scope)
    }

    fun delete(plant: Plant) {
        dbProvider.scope.launch {
            val coll = collection
            coll.getDocument(plant.name)?.let {
                coll.delete(it)
            }
        }
    }

    companion object {
        private const val PLANT_DOC_ID = "plant"
        private val debounceTime = 250.milliseconds
    }
}

