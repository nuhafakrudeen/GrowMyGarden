package com.gmg.growmygarden.network

import com.gmg.growmygarden.data.source.Plant
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.request.*
import kotlinx.serialization.Serializable
import com.gmg.growmygarden.data.source.PlantInfo



class TrefleApi(
    private val client: HttpClient,
    private val key: String
) {

    suspend fun searchTrefleAPI(query: String): List<PlantInfo>{
        return client.get("https://trefle.io/api/v1/plants/search") {
            parameter("q", query)
            parameter("token", key)
        }.body()
    }

    suspend fun searchPlantInTrefleAPI(id: Int): PlantInfo{
        return client.get("https://trefle.io/api/v1/plants/$id") {
            parameter("token", key)
        }.body()
    }

}