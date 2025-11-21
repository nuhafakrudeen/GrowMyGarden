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

    suspend fun searchTrefleAPI(query: String): List<PlantInfo> {
        val pulledPlantInfo: PerenualListResponse<PlantInfo> = client.get(
            "https://perenual.com/api/species-list",
        ) {
            parameter("q", query)
            parameter("token", key)
        }.body()

        return pulledPlantInfo.data
    }

    suspend fun searchPlantInTrefleAPI(id: Int): PlantInfo {
        val pulledPlantInfo: PerenualSingleResponse<PlantInfo> = client.get(
            "https://perenual.com/api/v2/species/details/$id",
        ) {
            parameter("token", key)
        }.body()

        return pulledPlantInfo.data
    }
}
