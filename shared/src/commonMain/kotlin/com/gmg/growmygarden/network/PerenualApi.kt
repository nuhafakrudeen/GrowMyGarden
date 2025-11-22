package com.gmg.growmygarden.network

import com.gmg.growmygarden.data.source.PlantInfo
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import kotlinx.serialization.Serializable

@Serializable
data class PerenualListResponse<T>(
    val data: List<T>,
)

@Serializable
data class PerenualSingleResponse<T>(
    val data: T,
)

class PerenualApi(
    private val client: HttpClient,
    private val key: String,
) {

    suspend fun searchPerenualAPI(query: String): List<PlantInfo> {
        val pulledPlantInfo: PerenualListResponse<PlantInfo> = client.get(
            "species-list",
        ) {
            url.parameters.append("q", query)
        }.body()

        return pulledPlantInfo.data
    }

    suspend fun searchPlantInPerenualAPI(id: Int): PlantInfo {
        val pulledPlantInfo: PerenualSingleResponse<PlantInfo> = client.get(
            "species/details/$id",
        ).body()

        return pulledPlantInfo.data
    }
}
