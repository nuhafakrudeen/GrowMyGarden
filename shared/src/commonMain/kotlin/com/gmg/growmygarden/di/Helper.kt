package com.gmg.growmygarden.di

import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.viewmodel.DashboardViewModel
import com.gmg.growmygarden.data.source.PlantImageStore
import io.github.vinceglb.filekit.FileKit
import io.github.vinceglb.filekit.div
import io.github.vinceglb.filekit.filesDir
import io.github.vinceglb.filekit.readBytes
import org.koin.core.context.startKoin
import org.koin.mp.KoinPlatformTools
import kotlin.time.Duration
import kotlin.time.Duration.Companion.days

/**
 * Initialize Koin from iOS.
 */
fun initKoin(apiKey: String) {
    val context = KoinPlatformTools.defaultContext().getOrNull()
    if (context == null) {
        startKoin {
            val props = getPropertiesMap().toMutableMap()
            props["PERENUAL_API_KEY"] = apiKey
            properties(props)
            modules(appModule())
        }
    }
}

// 1. Ensure this is public to match the actual implementation
expect fun getPropertiesMap(): Map<String, Any>

@Suppress("unused")
fun doInitKoin(apiKey: String) = initKoin(apiKey)

fun getDashboardViewModel(): DashboardViewModel {
    val koin = KoinPlatformTools.defaultContext().get()
    return koin.get(clazz = DashboardViewModel::class)
}

fun createBackendPlant(
    name: String,
    species: String,
    waterDays: Int,
    fertilizeDays: Int
): Plant {
    return Plant(
        name = name,
        species = species,
        wateringFrequency = if (waterDays > 0) waterDays.days else Duration.ZERO,
        fertilizingFrequency = if (fertilizeDays > 0) fertilizeDays.days else Duration.ZERO
    )
}

fun savePlantImage(plant: Plant, imageData: ByteArray) {
    val koin = KoinPlatformTools.defaultContext().get()
    val imageStore = koin.get<PlantImageStore>()
    val plantImage = imageStore.saveImage(imageData)
    plant.image = plantImage
}

// 2. FIX: Use try-catch instead of .exists()
suspend fun getPlantImageData(plant: Plant): ByteArray? {
    val imagePath = plant.image?.hqPath ?: return null
    val file = FileKit.filesDir / imagePath

    return try {
        file.readBytes()
    } catch (e: Exception) {
        null
    }
}

// 3. FIX: Add this helper for Swift to read Duration days
fun durationToDays(duration: Duration): Int {
    return duration.inWholeDays.toInt()
}