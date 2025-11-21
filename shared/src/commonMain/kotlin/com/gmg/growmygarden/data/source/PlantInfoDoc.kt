package com.gmg.growmygarden.data.source

import com.gmg.growmygarden.data.image.PlantImage
import com.gmg.growmygarden.data.image.PlantImageSerializer
import kotbase.Document
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class PlantInfoDoc (
    val id: Int = 0,
    val name: String = "",
    val scientificName: String = "",
    val species: String = "",
    val waterFrequency: String = "",
    val sunExposure: String = "",

    @Serializable(with = PlantImageSerializer::class)
    var image: PlantImage? = null,
)

fun decodePlantInfoDocument(doc: Document?): PlantInfoDoc? {
    return doc?.toJSON()?.let { json ->
        Json.decodeFromString<PlantInfoDoc>(json)
    }
}