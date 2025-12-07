package com.gmg.growmygarden.data.source

import kotbase.Document
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlin.uuid.Uuid

@Serializable
data class PlantInfoDoc(
    val docId: Uuid = Uuid.random(),
    val id: Int = 0,

    @SerialName("common_name")
    val name: String? = "",

    @SerialName("scientific_name")
    val scientificName: String? = "",

    @SerialName("family")
    val family: String? = "",

    // Simple watering string: "Frequent", "Average", "Minimum"
    @SerialName("watering")
    val watering: String? = null,

    @SerialName("sunlight")
    val sunExposure: List<String>? = null,

    @SerialName("default_image")
    var image: PlantImageInfo? = null,
)

fun decodePlantInfoDocument(doc: Document?): PlantInfoDoc? {
    return doc?.toJSON()?.let { json ->
        Json { ignoreUnknownKeys = true }.decodeFromString<PlantInfoDoc>(json)
    }
}
