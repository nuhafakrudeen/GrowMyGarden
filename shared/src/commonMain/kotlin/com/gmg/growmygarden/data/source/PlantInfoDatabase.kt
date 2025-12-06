package com.gmg.growmygarden.data.source

import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.network.PerenualApi // Ensure this import matches your package
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines
import kotbase.DataSource
import kotbase.Expression
import kotbase.FullTextFunction
import kotbase.FullTextIndexItem
import kotbase.IndexBuilder
import kotbase.Meta
import kotbase.MutableDocument
import kotbase.QueryBuilder
import kotbase.SelectResult
import kotbase.get
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
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonIgnoreUnknownKeys
import kotlinx.serialization.json.JsonTransformingSerializer
import kotlin.Int
import kotlin.time.Duration.Companion.milliseconds
import kotlin.uuid.Uuid

// 1. Apply the custom serializer to 'sunExposure'
@Serializable
@JsonIgnoreUnknownKeys
data class PlantInfo(
    val docId: Uuid = Uuid.random(),
    val id: Int = 0,
    @SerialName("common_name")
    val name: String? = null,
    @SerialName("scientific_name")
    val scientificName: List<String>? = null,
    @SerialName("family")
    val family: String? = null,
    @SerialName("water")
    val waterInfo: WaterInfo? = null,

    @Serializable(with = StringOrListSerializer::class) // 👈 THIS FIXES THE CRASH
    @SerialName("sunlight")
    val sunExposure: List<String>? = null,

    @SerialName("default_image")
    var image: PlantImageInfo? = null,
)

@Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")
open class PlantInfoRepository(
    private val dbProvider: DatabaseProvider,
    private val api: PerenualApi,
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

    fun savePlantInfo(plantInfo: PlantInfo) {
        saveChannel.trySend(plantInfo)
    }

    @NativeCoroutines
    suspend fun saveMultiplePlantInfo(vararg multiplePlantInfo: PlantInfo) {
        for (plantInfo in multiplePlantInfo) {
            savePlantInfo(plantInfo)
            delay(300.milliseconds)
        }
    }

    // 2. Network Search Function (Clean version)
    suspend fun searchRemotePlants(query: String): List<PlantInfo> {
        return try {
            api.searchPerenualAPI(query)
        } catch (e: Exception) {
            println("Error searching remote API: ${e.message}")
            emptyList()
        }
    }

    private fun docToPlantInfo(plantInfoDoc: PlantInfoDoc): PlantInfo {
        return PlantInfo(
            docId = plantInfoDoc.docId,
            id = plantInfoDoc.id,
            name = plantInfoDoc.name,
            scientificName = plantInfoDoc.scientificName?.split(", ") ?: emptyList(),
            family = plantInfoDoc.family,
            waterInfo = plantInfoDoc.waterInfo,
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
                val doc = coll.getDocument(plantInfo.docId.toHexDashString())
                    ?.let(::decodePlantInfoDocument)
                    ?: PlantInfoDoc()
                val updated = doc.copy(
                    docId = plantInfo.docId,
                    id = plantInfo.id,
                    name = plantInfo.name,
                    scientificName = plantInfo.scientificName?.joinToString(", "),
                    waterInfo = plantInfo.waterInfo,
                    sunExposure = plantInfo.sunExposure,
                    image = plantInfo.image,
                )
                val json = Json.encodeToString(updated)
                val mutableDoc = MutableDocument(plantInfo.docId.toHexDashString(), json)
                coll.save(mutableDoc)
            }
            .launchIn(dbProvider.scope)
    }

    init {
        collection.createIndex(
            "plantInfoFTSIndex",
            IndexBuilder.fullTextIndex(
                FullTextIndexItem.property("name"),
                FullTextIndexItem.property("scientificName"),
                FullTextIndexItem.property("family"),
            ).ignoreAccents(false),
        )
    }

    suspend fun searchPlantInfo(keyWords: String): List<PlantInfo> {
        val ftsQuery =
            QueryBuilder.select(
                SelectResult.expression(Meta.id),
            )
                .from(DataSource.collection(collection))
                .where(
                    FullTextFunction.match(
                        Expression.fullTextIndex("plantInfoFTSIndex"),
                        keyWords,
                    ),
                )

        val ftsResults = ftsQuery.execute().use { rs ->
            rs.allResults()
        }

        val plantInfoFileID = ftsResults.mapNotNull { result ->
            result.getString("id")
        }

        return plantInfoFileID.mapNotNull { docId ->
            collection.getDocument(docId)
                ?.let(::decodePlantInfoDocument)
                ?.let(::docToPlantInfo)
        }
    }
}

// 3. The Custom Serializer Helper
object StringOrListSerializer : JsonTransformingSerializer<List<String>>(ListSerializer(String.serializer())) {
    override fun transformDeserialize(element: JsonElement): JsonElement {
        return if (element !is JsonArray) {
            // If the API sends a String (the upgrade ad), wrap it in a list so parsing succeeds
            JsonArray(listOf(element))
        } else {
            element
        }
    }
}
