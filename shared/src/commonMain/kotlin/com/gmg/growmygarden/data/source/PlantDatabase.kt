@file:OptIn(ExperimentalUuidApi::class)

package com.gmg.growmygarden.data.source

import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.data.image.PlantImage
import com.gmg.growmygarden.data.image.PlantImageSerializer
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines
import kotbase.Expression
import kotbase.MutableDocument
import kotbase.ktx.all
import kotbase.ktx.asObjectsFlow
import kotbase.ktx.from
import kotbase.ktx.orderBy
import kotbase.ktx.select
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlin.String
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

@Serializable
data class Plant(
    val uuid: Uuid = Uuid.random(),
    val userId: String = "",
    val name: String = "",
    val scientificName: String = "",
    val species: String = "",
    var wateringFrequency: Duration = Duration.ZERO,
    var wateringNotificationID: Uuid? = null,
    var fertilizingFrequency: Duration = Duration.ZERO,
    var fertilizerNotificationID: Uuid? = null,
    var trimmingFrequency: Duration = Duration.ZERO,
    var trimmingNotificationID: Uuid? = null,

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
) {
    private val currentUserId = MutableStateFlow<String?>(null)

    fun setUserId(id: String?) {
        currentUserId.value = id
    }

    @Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")
    internal val collection
        get() = dbProvider.database.createCollection(COLLECTION_NAME)

    @NativeCoroutines
    val plants: Flow<List<Plant>>
        get() {
            return currentUserId.flatMapLatest { userId ->
                if (userId.isNullOrEmpty()) {
                    flowOf(emptyList())
                } else {
                    val query = select(all())
                        .from(collection)
                        .where(Expression.property("userId").equalTo(Expression.string(userId)))
                        .orderBy { "name".descending() }

                    query.asObjectsFlow { json: String ->
                        Json.decodeFromString<Plant>(json)
                    }
                }
            }
        }

    private val saveChannel = Channel<Plant>(Channel.CONFLATED)

    fun savePlant(plant: Plant) {
        val uid = currentUserId.value ?: return
        val plantWithUser = plant.copy(userId = uid)
        saveChannel.trySend(plantWithUser)
    }

    @NativeCoroutines
    suspend fun savePlants(vararg plants: Plant) {
        for (plant in plants) {
            savePlant(plant)
            delay(debounceTime + 50.milliseconds)
        }
    }

    fun delete(plant: Plant) {
        dbProvider.scope.launch {
            val coll = collection
            coll.getDocument(plant.uuid.toHexDashString())?.let {
                coll.delete(it)
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
            userId = doc.userId,
            name = doc.name,
            species = doc.species,
            scientificName = doc.scientificName,
            wateringFrequency = doc.wateringFrequency,
            wateringNotificationID = doc.wateringNotificationID,
            fertilizingFrequency = doc.fertilizingFrequency,
            fertilizerNotificationID = doc.fertilizerNotificationID,
            trimmingFrequency = doc.trimmingFrequency,
            trimmingNotificationID = doc.trimmingNotificationID,
            image = doc.image,
        )
    }

    init {
        @OptIn(FlowPreview::class)
        saveChannel.receiveAsFlow()
            .debounce(debounceTime)
            .onEach { plant ->
                val coll = collection
                val doc = coll.getDocument(plant.uuid.toHexDashString())
                    ?.let(::decodeDocument)
                    ?: PlantDoc()

                val updated = doc.copy(
                    uuid = plant.uuid,
                    userId = plant.userId,
                    name = plant.name,
                    scientificName = plant.scientificName,
                    species = plant.species,
                    wateringFrequency = plant.wateringFrequency,
                    wateringNotificationID = plant.wateringNotificationID,
                    fertilizingFrequency = plant.fertilizingFrequency,
                    fertilizerNotificationID = plant.fertilizerNotificationID,
                    trimmingFrequency = plant.trimmingFrequency,
                    trimmingNotificationID = plant.trimmingNotificationID,
                    image = plant.image,
                )
                val json = Json.encodeToString(updated)
                val mutableDoc = MutableDocument(plant.uuid.toHexDashString(), json)
                coll.save(mutableDoc)
            }
            .launchIn(dbProvider.scope)
    }

    companion object {
        private const val PLANT_DOC_ID = "plant"
        private const val COLLECTION_NAME = "plants"
        private val debounceTime = 250.milliseconds
    }
}
