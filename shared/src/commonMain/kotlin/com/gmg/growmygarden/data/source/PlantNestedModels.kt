package com.gmg.growmygarden.data.source

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Nested model classes for plant data from the Perenual API.
 */

@Serializable
data class PlantImageInfo(
    @SerialName("image_id")
    val imageId: Int? = null,
    val license: Int? = null,
    @SerialName("license_name")
    val licenseName: String? = null,
    @SerialName("license_url")
    val licenseUrl: String? = null,
    @SerialName("original_url")
    val originalUrl: String? = null,
    @SerialName("regular_url")
    val regularUrl: String? = null,
    @SerialName("medium_url")
    val mediumUrl: String? = null,
    @SerialName("small_url")
    val smallUrl: String? = null,
    val thumbnail: String? = null,
)

/**
 * Placeholder for future premium API fields.
 * Watering benchmark and pruning details require a paid Perenual plan.
 */
@Serializable
data class WateringBenchmark(
    @SerialName("value")
    val value: String? = null,
    @SerialName("unit")
    val unit: String? = null,
)

@Serializable
data class PruningCount(
    @SerialName("amount")
    val amount: Int? = null,
    @SerialName("interval")
    val interval: String? = null,
)
