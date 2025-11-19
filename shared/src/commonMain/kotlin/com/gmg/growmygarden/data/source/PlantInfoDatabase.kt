package com.gmg.growmygarden.data.source

import kotlinx.serialization.Serializable

@Serializable
data class PlantInfo(
    val id: Int,
    val name: String? = null,
    val scientificName: String? = null,
    val species: String? = null,

)