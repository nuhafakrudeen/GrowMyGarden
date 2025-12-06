package com.gmg.growmygarden.network

import com.gmg.growmygarden.data.source.PlantInfo
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.request.get
import kotlinx.serialization.Serializable
import io.ktor.client.statement.bodyAsText
import kotlinx.serialization.json.Json
@Serializable
data class PerenualListResponse<T>(val data: List<T>)

class PerenualApi(
    private val client: HttpClient,
    private val apiKey: String
) {

    // ✅ This is the function the build error said was missing.
    // Ensure it is pasted exactly like this.
    suspend fun searchPerenualAPI(query: String): List<PlantInfo> {
        val pulledPlantInfo: PerenualListResponse<PlantInfo> = client.get("species-list") {
            url.parameters.append("q", query)
            url.parameters.append("key", apiKey)
        }.body()

        return pulledPlantInfo.data
    }

    suspend fun searchPlantInPerenualAPI(id: Int): PlantInfo {
        return client.get("species/details/$id") {
            url.parameters.append("key", apiKey)
        }.body()
    }
}