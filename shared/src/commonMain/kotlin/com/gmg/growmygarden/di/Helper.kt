package com.gmg.growmygarden.di

import org.koin.core.context.startKoin

fun initKoin() {
    startKoin {
        val props = try {
            getPropertiesMap()
        } catch (e: Exception) {
            println("Failed to load Properties: $e")
            println(e.stackTraceToString())
            emptyMap()
        }

        properties(props)
        modules(appModule())
    }
}

internal expect fun getPropertiesMap(): Map<String, Any>
