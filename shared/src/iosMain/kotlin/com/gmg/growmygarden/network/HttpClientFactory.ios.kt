package com.gmg.growmygarden.network

import io.ktor.client.HttpClient
import io.ktor.client.engine.darwin.Darwin
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.defaultRequest
import io.ktor.http.URLProtocol
import io.ktor.http.appendPathSegments
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json

actual fun createHttpClient(perenualKey: String): HttpClient = HttpClient(Darwin.create()) {
    install(ContentNegotiation) {
        json(Json { ignoreUnknownKeys = true })
    }
    if (perenualKey.isEmpty()) {
        println("API Key is Empty")
    }
    defaultRequest {
        url {
            protocol = URLProtocol.HTTPS
            host = "perenual.com"
            appendPathSegments("api", "v2")
            parameters.append("key", perenualKey)
        }
    }
}
