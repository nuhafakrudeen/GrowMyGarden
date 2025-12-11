package com.gmg.growmygarden.di

import com.gmg.growmygarden.data.image.PlantImage
import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.data.source.PlantInfoRepository
import com.gmg.growmygarden.viewmodel.DashboardViewModel
import org.koin.core.context.startKoin
import org.koin.mp.KoinPlatformTools
import kotlin.time.Duration.Companion.milliseconds
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

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

internal expect fun getPropertiesMap(): Map<String, Any>

@Suppress("unused")
fun doInitKoin(apiKey: String) = initKoin(apiKey)

fun getDashboardViewModel(): DashboardViewModel {
    val koin = KoinPlatformTools.defaultContext().get()
    return koin.get(clazz = DashboardViewModel::class)
}

fun getPlantInfoRepository(): PlantInfoRepository {
    val koin = KoinPlatformTools.defaultContext().get()
    return koin.get(clazz = PlantInfoRepository::class)
}

@OptIn(ExperimentalUuidApi::class)
fun createBackendPlant(
    idString: String?,
    name: String,
    species: String,
    waterFreqMillis: Long,
    waterEnabled: Boolean,
    fertFreqMillis: Long,
    fertEnabled: Boolean,
    trimFreqMillis: Long,
    trimEnabled: Boolean,
    imageBytes: ByteArray? = null,
    notes: String = "",
): Plant {
    val uuid = if (idString != null) Uuid.parse(idString) else Uuid.random()

    // Create PlantImage with the bytes if provided
    val plantImage: PlantImage? = if (imageBytes != null && imageBytes.isNotEmpty()) {
        PlantImage(imageBytes = imageBytes)
    } else {
        null
    }

    return Plant(
        uuid = uuid,
        name = name,
        species = species,
        wateringFrequency = waterFreqMillis.milliseconds,
        wateringNotificationID = if (waterEnabled) Uuid.random() else null,
        fertilizingFrequency = fertFreqMillis.milliseconds,
        fertilizerNotificationID = if (fertEnabled) Uuid.random() else null,
        trimmingFrequency = trimFreqMillis.milliseconds,
        trimmingNotificationID = if (trimEnabled) Uuid.random() else null,
        notes = notes,
        image = plantImage,
    )
}

/**
 * Create a backend plant and automatically fetch image from Perenual API.
 * Use this when creating a new plant to auto-populate the image based on species.
 *
 * @param shouldAutoFetchImage If true and no imageBytes provided, will attempt to fetch
 *                              image from Perenual API based on species name
 */
@OptIn(ExperimentalUuidApi::class)
fun createBackendPlantWithAutoImage(
    idString: String?,
    name: String,
    species: String,
    waterFreqMillis: Long,
    waterEnabled: Boolean,
    fertFreqMillis: Long,
    fertEnabled: Boolean,
    trimFreqMillis: Long,
    trimEnabled: Boolean,
    imageBytes: ByteArray? = null,
    shouldAutoFetchImage: Boolean = true,
    notes: String = "",
): Plant {
    val uuid = if (idString != null) Uuid.parse(idString) else Uuid.random()

    // Create PlantImage with the bytes if provided
    val plantImage: PlantImage? = if (imageBytes != null && imageBytes.isNotEmpty()) {
        PlantImage(imageBytes = imageBytes)
    } else {
        null
    }

    return Plant(
        uuid = uuid,
        name = name,
        species = species,
        wateringFrequency = waterFreqMillis.milliseconds,
        wateringNotificationID = if (waterEnabled) Uuid.random() else null,
        fertilizingFrequency = fertFreqMillis.milliseconds,
        fertilizerNotificationID = if (fertEnabled) Uuid.random() else null,
        trimmingFrequency = trimFreqMillis.milliseconds,
        trimmingNotificationID = if (trimEnabled) Uuid.random() else null,
        notes = notes,
        image = plantImage,
    )
}
