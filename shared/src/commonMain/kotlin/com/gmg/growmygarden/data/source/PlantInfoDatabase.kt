package com.gmg.growmygarden.data.source

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
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlin.Int
import kotlin.time.Duration.Companion.milliseconds

@Serializable
data class PlantInfo(
    val id: Int,
    val name: String? = null,
    val scientificName: String? = null,
    val species: String? = null,
    val waterFrequency: String? = null,
    val sunExposure: String? = null,

    @Serializable(with = PlantImageSerializer::class)
    var image: PlantImage? = null,
)

@Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")
open class PlantInfoRepository(
    private val dbProvider: DatabaseProvider
) {

    @Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")
    internal val collection
        get() = dbProvider.database.createCollection("plantInfo")

    @NativeCoroutines
    val plantInfoList: Flow<List<PlantInfo>>
        get() {
            val query = select(all()) from collection orderBy { "id".descending() }
            return query.asObjectsFlow { json: String ->
                Json.decodeFromString<PlantInfo>(json)
            }
        }

    private val saveChannel = Channel<PlantInfo>(Channel.CONFLATED)

    fun savePlantInfo(plantInfo: PlantInfo)
    {
        saveChannel.trySend(plantInfo)
    }

    @NativeCoroutines
    suspend fun saveMultiplePlantInfo(vararg multiplePlantInfo: PlantInfo) {
        for (plantInfo in multiplePlantInfo) {
            savePlantInfo(plantInfo)
            delay(300.milliseconds)
        }
    }

    private fun docToPlantInfo(plantInfoDoc: PlantInfoDoc): PlantInfo{
        return PlantInfo(
            id = plantInfoDoc.id,
            name = plantInfoDoc.name,
            scientificName = plantInfoDoc.scientificName,
            species = plantInfoDoc.species,
            waterFrequency = plantInfoDoc.waterFrequency,
            sunExposure = plantInfoDoc.sunExposure,
            image = plantInfoDoc.image,
        )
    }

    init {
        @OptIn(FlowPreview::class)
        saveChannel.receiveAsFlow()
            .debounce(250.milliseconds)
            .onEach { plantInfo ->
                val coll = collection
                val doc = coll.getDocument(plantInfo.id.toString())
                    ?.let(::decodePlantInfoDocument)
                    ?: PlantInfoDoc()
                val updated = doc.copy(
                    id = plantInfo.id,
                    name = plantInfo.name,
                    scientificName = plantInfo.scientificName,
                    waterFrequency = plantInfo.waterFrequency,
                    sunExposure = plantInfo.sunExposure,
                    image = plantInfo.image
                )
                val json = Json.encodeToString(updated)
                val mutableDoc = MutableDocument(plantInfo.id.toString(), json)
                coll.save(mutableDoc)
            }
            .launchIn(dbProvider.scope)
    }

}