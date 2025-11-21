package com.gmg.growmygarden.network

import io.ktor.client.*
import io.ktor.client.engine.darwin.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json


actual fun createHttpClient(): HttpClient = HttpClient(Darwin.create()) {
    install(ContentNegotiation) {
        json(Json { ignoreUnknownKeys = true })
    }
}
