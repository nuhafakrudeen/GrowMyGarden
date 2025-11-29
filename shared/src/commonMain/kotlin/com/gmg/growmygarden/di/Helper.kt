package com.gmg.growmygarden.di

import org.koin.core.context.startKoin

fun initKoin() {
    startKoin {
        properties(getPropertiesMap())
        modules(appModule())
    }
}

internal expect fun getPropertiesMap(): Map<String, Any>
