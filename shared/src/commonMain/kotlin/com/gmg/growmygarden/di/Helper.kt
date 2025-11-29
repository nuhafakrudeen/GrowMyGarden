package com.gmg.growmygarden.di

import org.koin.core.context.startKoin

fun initKoin() {
    startKoin {
        val props = try {
            getPropertiesMap()
        } catch (e: Exception) {
            println("Failed to load Properties: $e")
            e.printStackTrace()
            emptyMap()
        }

        println("Successfully Loaded Properties")
        properties(props)
        modules(appModule())
    }
    println("Finished Loading Koin")
}

internal expect fun getPropertiesMap(): Map<String, Any>
