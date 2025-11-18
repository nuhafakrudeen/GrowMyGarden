package com.gmg.growmygarden.di

import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.viewmodel.DashboardViewModel
import org.koin.core.context.startKoin
import org.koin.mp.KoinPlatformTools

/**
 * Initialize Koin from iOS. Safe to call multiple times.
 */
fun initKoin() {
    val context = KoinPlatformTools.defaultContext().getOrNull()
    if (context == null) {
        startKoin {
            modules(appModule())
        }
    }
}

/**
 * Some Swift toolchains expose only this wrapper (HelperKt.doInitKoin()).
 * It simply delegates to initKoin().
 */
@Suppress("unused")
fun doInitKoin() = initKoin()

/**
 * Resolve the shared DashboardViewModel instance for iOS.
 */
fun getDashboardViewModel(): DashboardViewModel {
    val koin = KoinPlatformTools.defaultContext().get()
    return koin.get(clazz = DashboardViewModel::class)
}

/**
 * Helper for iOS: construct a backend Plant with default values,
 * so Swift does not need to know about uuid / durations / image types.
 */
fun createBackendPlant(name: String, species: String): Plant {
    return Plant(name = name, species = species)
}
