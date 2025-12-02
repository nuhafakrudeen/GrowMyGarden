package com.gmg.growmygarden.di

import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.viewmodel.DashboardViewModel
import org.koin.core.context.startKoin
import org.koin.mp.KoinPlatformTools

/**
 * Initialize Koin from iOS. Safe to call multiple times.
 * Update: Accepts apiKey to ensure Koin has the property required by ApiModule.
 */
fun initKoin(apiKey: String) {
    val context = KoinPlatformTools.defaultContext().getOrNull()
    if (context == null) {
        startKoin {
            // Get existing properties (if any implementation exists)
            val props = getPropertiesMap().toMutableMap()
            // Manually add the missing key that ApiModule needs
            props["PERENUAL_API_KEY"] = apiKey

            properties(props)
            modules(appModule())
        }
    } else {
        // Already started, nothing to do.
    }
}

/**
 * Expect actual implementation on iOS (see Helper.ios.kt).
 */
internal expect fun getPropertiesMap(): Map<String, Any>

/**
 * Convenience wrapper used from Swift as `HelperKt.doInitKoin()`.
 */
@Suppress("unused")
fun doInitKoin(apiKey: String) = initKoin(apiKey)

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
