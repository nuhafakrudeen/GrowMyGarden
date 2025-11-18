package com.gmg.growmygarden.di

import com.gmg.growmygarden.viewmodel.DashboardViewModel
import org.koin.core.context.startKoin
import org.koin.mp.KoinPlatformTools

/**
 * Main Koin initializer.
 */
fun initKoin() {
    println("✅ initKoin called from iOS")

    val context = KoinPlatformTools.defaultContext().getOrNull()
    if (context == null) {
        startKoin {
            modules(appModule())
        }
        println("✅ Koin started successfully")
    } else {
        println("ℹ️ Koin was already started, skipping")
    }
}


/**
 * Compatibility wrapper for Swift – this is the name Xcode sees
 * as HelperKt.doInitKoin().
 */
@Suppress("unused")
fun doInitKoin() = initKoin()

/**
 * Get DashboardViewModel from Koin.
 */
fun getDashboardViewModel(): DashboardViewModel {
    val koin = KoinPlatformTools.defaultContext().get()
    return koin.get(clazz = DashboardViewModel::class)
}
