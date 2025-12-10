package com.gmg.growmygarden.network

import io.ktor.client.HttpClient

/**
 * Expects function to define creation of version specific HttpClient
 */
expect fun createHttpClient(perenualKey: String): HttpClient
