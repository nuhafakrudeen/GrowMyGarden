@file:Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")
@file:OptIn(ExperimentalUuidApi::class)

package com.gmg.growmygarden.data.source

import com.gmg.growmygarden.data.image.PlantImage
import com.gmg.growmygarden.data.image.PlantImageSerializer
import kotbase.Document
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlin.time.Duration
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

@Serializable
data class PlantDoc(
    val uuid: Uuid = Uuid.random(),
    val userId: String? = null,
    val name: String = "",
    val scientificName: String = "",
    val species: String = "",
    val wateringFrequency: Duration = Duration.ZERO,
    var wateringNotificationID: Uuid? = null,
    val fertilizingFrequency: Duration = Duration.ZERO,
    var fertilizerNotificationID: Uuid? = null,
    var trimmingFrequency: Duration = Duration.ZERO,
    var trimmingNotificationID: Uuid? = null,
    @Serializable(with = PlantImageSerializer::class)
    var image: PlantImage? = null,
)

fun decodeDocument(doc: Document?): PlantDoc? {
    return doc?.toJSON()?.let { json ->
        Json.decodeFromString<PlantDoc>(json)
    }
}
