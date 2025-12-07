package com.gmg.growmygarden.data.source

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

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

// Note: WateringBenchmark and PruningCount require premium API access
// Keeping simple models for free tier
