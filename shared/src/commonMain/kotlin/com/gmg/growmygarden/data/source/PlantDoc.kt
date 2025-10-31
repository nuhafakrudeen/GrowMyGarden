@file:Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")
@file:OptIn(ExperimentalUuidApi::class)

package com.gmg.growmygarden.data.source

import kotbase.Document
import kotlinx.io.files.Path
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlin.time.Duration
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

@Serializable
data class PlantDoc(
    val uuid: Uuid = Uuid.random(),
    val name: String = "",
    val scientificName: String = "",
    val species: String = "",
    val wateringFrequency: Duration = Duration.ZERO,
    val fertilizingFrequency: Duration = Duration.ZERO,
    val imagePath: String? = null,
)

fun decodeDocument(doc: Document?): PlantDoc? {
    return doc?.toJSON()?.let { json ->
        Json.decodeFromString<PlantDoc>(json)
    }
}

