@file:Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")

package com.gmg.growmygarden.data.source

import kotbase.Document
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlin.time.Duration

@Serializable
data class PlantDoc(
    val name: String = "",
    val scientificName: String = "",
    val species: String = "",
    val wateringFrequency: Duration = Duration.ZERO,
    val fertilizingFrequency: Duration = Duration.ZERO
)

fun decodeDocument(doc: Document?): PlantDoc? {
    return doc?.toJSON()?.let { json ->
        Json.decodeFromString<PlantDoc>(json)
    }
}

