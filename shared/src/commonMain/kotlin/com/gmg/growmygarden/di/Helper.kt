package com.gmg.growmygarden.di

import androidx.compose.runtime.TestOnly
import org.koin.core.context.startKoin

fun initKoin() {
    startKoin {
        val props = getPropertiesMap()
        properties(props)
        modules(appModule())
    }
}

internal expect fun getPropertiesMap(): Map<String, Any>

@TestOnly
internal expect fun loadSecretsFromFileSystem(): Map<String, Any>
