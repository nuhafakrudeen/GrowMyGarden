@file:OptIn(ExperimentalUuidApi::class)

package com.gmg.growmygarden.data.source

import com.gmg.growmygarden.auth.UserManager
import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.data.image.PlantImage
import com.gmg.growmygarden.data.image.PlantImageSerializer
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines
import kotbase.MutableDocument
import kotbase.ktx.all
import kotbase.ktx.asObjectsFlow
import kotbase.ktx.from
import kotbase.ktx.orderBy
import kotbase.ktx.select
import kotbase.ktx.where
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonIgnoreUnknownKeys // ✅ 1. ADD THIS IMPORT
import kotlin.String
import kotlin.time.Duration
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
@JsonIgnoreUnknownKeys
data class Plant(
    val uuid: Uuid = Uuid.random(),
    val name: String = "",
    val scientificName: String = "",
    val species: String = "",
    var wateringFrequency: Duration = Duration.ZERO,
    var wateringNotificationID: Uuid? = null,
    var fertilizingFrequency: Duration = Duration.ZERO,
    var fertilizerNotificationID: Uuid? = null,
    var trimmingFrequency: Duration = Duration.ZERO,
    var trimmingNotificationID: Uuid? = null,

    var notes: String = "",

    @Serializable(with = PlantImageSerializer::class)
    var image: PlantImage? = null,
) {
    val waterMillis: Long
        get() = wateringFrequency.inWholeMilliseconds

    val fertMillis: Long
        get() = fertilizingFrequency.inWholeMilliseconds

    val trimMillis: Long
        get() = trimmingFrequency.inWholeMilliseconds
}

@Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")
open class PlantRepository(
    private val dbProvider: DatabaseProvider,
    private val userManager: UserManager,
) {
    @Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")
    internal val collection by lazy { dbProvider.database.getCollection(COLLECTION_NAME) ?: dbProvider.database.createCollection(COLLECTION_NAME) }


    @NativeCoroutines
    val plants: Flow<List<Plant>>
        get() {
            val query = userManager.user?.let { user ->
                select(all()) from collection where {
                    "userId" equalTo user.id
                } orderBy { "name".descending() }
            } ?: run { select(all()) from collection orderBy { "name".descending() } }

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
            delay(debounceTime + 50.milliseconds)
        }
    }

    fun delete(plant: Plant) {
        val docId = plant.uuid.toHexDashString()
        println("🗑️ KOTLIN DELETE ATTEMPT:")
        println("   Plant name: ${plant.name}")
        println("   Document ID: $docId")

        dbProvider.scope.launch {
            val coll = collection
            val doc = coll.getDocument(docId)
            println("   Document found: ${doc != null}")

            if (doc != null) {
                coll.delete(doc)
                println("✅ KOTLIN: Document deleted successfully")

                // Verify deletion
                val verifyDoc = coll.getDocument(docId)
                println("   VERIFY after delete - Document still exists: ${verifyDoc != null}")

                // Also check collection count
                val allDocs = coll.count
                println("   Total documents in collection after delete: $allDocs")
            } else {
                println("❌ KOTLIN: Document NOT FOUND - cannot delete")
            }
        }
    }

    @NativeCoroutines
    suspend fun getPlant(id: String): Plant? {
        return withContext(dbProvider.readContext) {
            collection.getDocument(id)
                ?.let(::decodeDocument)
                ?.let(::docToPlant)
        }
    }

    @NativeCoroutines
    suspend fun getPlant(uuid: Uuid): Plant? {
        return getPlant(uuid.toHexDashString())
    }

    private fun docToPlant(doc: PlantDoc): Plant {
        return Plant(
            uuid = doc.uuid,
            name = doc.name,
            species = doc.species,
            scientificName = doc.scientificName,
            wateringFrequency = doc.wateringFrequency,
            wateringNotificationID = doc.wateringNotificationID,
            fertilizingFrequency = doc.fertilizingFrequency,
            fertilizerNotificationID = doc.fertilizerNotificationID,
            trimmingFrequency = doc.trimmingFrequency,
            trimmingNotificationID = doc.trimmingNotificationID,
            notes = doc.notes,
            image = doc.image,
        )
    }

    init {
        @OptIn(FlowPreview::class)
        saveChannel.receiveAsFlow().debounce(debounceTime).onEach { plant ->
            val coll = collection
            println("    Saved Plant ${plant.uuid.toHexDashString()}")
            val doc = coll.getDocument(plant.uuid.toHexDashString())?.let(::decodeDocument) ?: PlantDoc()
            val updated = doc.copy(
                uuid = plant.uuid,
                userId = userManager.user?.id,
                name = plant.name,
                scientificName = plant.scientificName,
                species = plant.species,
                wateringFrequency = plant.wateringFrequency,
                wateringNotificationID = plant.wateringNotificationID,
                fertilizingFrequency = plant.fertilizingFrequency,
                fertilizerNotificationID = plant.fertilizerNotificationID,
                trimmingFrequency = plant.trimmingFrequency,
                trimmingNotificationID = plant.trimmingNotificationID,
                notes = plant.notes,
                image = plant.image,
            )
            val json = Json.encodeToString(updated)
            val mutableDoc = MutableDocument(plant.uuid.toHexDashString(), json)
            coll.save(mutableDoc)
        }.launchIn(dbProvider.scope)
    }

    companion object {
        private const val PLANT_DOC_ID = "plant"
        private const val COLLECTION_NAME = "plants"
        private val debounceTime = 250.milliseconds
    }
}
