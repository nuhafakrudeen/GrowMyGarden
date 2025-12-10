package com.gmg.growmygarden.viewmodel

import com.gmg.growmygarden.NotificationHandler
import com.gmg.growmygarden.auth.UserManager
import com.gmg.growmygarden.data.image.PlantImage
import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.data.source.PlantImageStore
import com.gmg.growmygarden.data.source.PlantInfo
import com.gmg.growmygarden.data.source.PlantInfoRepository
import com.gmg.growmygarden.data.source.PlantRepository
import com.gmg.growmygarden.network.PerenualApi
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines
import com.rickclephas.kmp.nativecoroutines.NativeCoroutinesState
import com.rickclephas.kmp.observableviewmodel.ViewModel
import com.rickclephas.kmp.observableviewmodel.launch
import com.rickclephas.kmp.observableviewmodel.stateIn
import io.github.vinceglb.filekit.FileKit
import io.github.vinceglb.filekit.dialogs.FileKitType
import io.github.vinceglb.filekit.dialogs.openFilePicker
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.datetime.LocalDateTime
import kotlin.collections.listOf
import kotlin.time.Duration
import kotlin.uuid.Uuid

class DashboardViewModel(
    private val plantRepository: PlantRepository,
    private val imageStore: PlantImageStore,
    private val notificationHandler: NotificationHandler,
    private val perenualAPI: PerenualApi,
    private val plantInfoRepository: PlantInfoRepository,
    private val userManager: UserManager,
) : ViewModel() {

    @NativeCoroutinesState
    val plantsState: StateFlow<List<Plant>> = plantRepository.plants.stateIn(
        viewModelScope,
        started = SharingStarted.WhileSubscribed(5000L),
        initialValue = listOf<Plant>(),
    )

    /**
     * Updates the repository with the current User ID.
     * Call this when the user logs in (with UID) or logs out (with null).
     */
    @Deprecated("Do Not Use", replaceWith = ReplaceWith("LoginViewModel.login(userId)"))
    fun setUserId(userId: String?) {
        if (userId != null) {
            userManager.login(userId)
        } else {
            userManager.logout()
        }
    }

    fun savePlant(plant: Plant) {
        plantRepository.savePlant(plant)
    }

    /**
     * Save a plant and automatically fetch an image from Perenual API if:
     * 1. The plant doesn't already have an image
     * 2. The species name matches a plant in the Perenual database
     *
     * This is called when creating a new plant to auto-populate the image.
     */
    fun savePlantWithAutoImage(plant: Plant) {
        viewModelScope.launch {
            // If plant already has an image, just save it normally
            if (plant.image != null && plant.image?.imageBytes != null) {
                plantRepository.savePlant(plant)
                return@launch
            }

            // Try to fetch image from Perenual API based on species
            val speciesQuery = plant.species.ifBlank { plant.name }
            if (speciesQuery.isBlank()) {
                plantRepository.savePlant(plant)
                return@launch
            }

            var updatedPlant = plant

            try {
                val (plantInfo, imageBytes) = perenualAPI.searchPlantAndGetImage(speciesQuery)

                if (imageBytes != null && imageBytes.isNotEmpty()) {
                    val plantImage = PlantImage(imageBytes = imageBytes)
                    updatedPlant = updatedPlant.copy(image = plantImage)

                    // REMOVED: imageStore.saveImage(imageBytes)
                    // The bytes are already stored in PlantImage, no need to save separately
                    // (and FileKit.compress crashes on non-image data)

                    println("✅ Auto-fetched image for '${updatedPlant.species}' from Perenual API")
                }

                // Update scientific name if we found a match and plant doesn't have one
                if (plantInfo != null && updatedPlant.scientificName.isBlank()) {
                    val sciName = plantInfo.scientificName?.firstOrNull() ?: ""
                    if (sciName.isNotBlank()) {
                        updatedPlant = updatedPlant.copy(scientificName = sciName)
                    }
                }
            } catch (e: Exception) {
                println("⚠️ Failed to auto-fetch image for '${plant.species}': ${e.message}")
            }

            // Always save the plant (with or without image)
            plantRepository.savePlant(updatedPlant)
        }
    }

    /**
     * Try to fetch and update an existing plant's image from Perenual API.
     * Useful for retroactively adding images to plants that were created without them.
     */
    @NativeCoroutines
    suspend fun fetchAndUpdatePlantImage(plant: Plant): Boolean {
        val speciesQuery = plant.species.ifBlank { plant.name }
        if (speciesQuery.isBlank()) return false

        return try {
            val (_, imageBytes) = perenualAPI.searchPlantAndGetImage(speciesQuery)

            if (imageBytes != null && imageBytes.isNotEmpty()) {
                val plantImage = PlantImage(imageBytes = imageBytes)
                plant.image = plantImage
                plantRepository.savePlant(plant)
                println("✅ Updated image for '${plant.species}' from Perenual API")
                true
            } else {
                false
            }
        } catch (e: Exception) {
            println("⚠️ Failed to fetch image for '${plant.species}': ${e.message}")
            false
        }
    }

    /**
     * Get PlantInfo from Perenual API by species name.
     * This can be used to show additional plant details or to verify species.
     */
    @NativeCoroutines
    suspend fun getPlantInfoBySpecies(speciesName: String): PlantInfo? {
        return try {
            perenualAPI.searchPlantBySpecies(speciesName)
        } catch (e: Exception) {
            println("Error fetching plant info for '$speciesName': ${e.message}")
            null
        }
    }

    /**
     * Get image URL for a species from Perenual API.
     * Returns the best available image URL or null if not found.
     */
    @NativeCoroutines
    suspend fun getPlantImageUrl(speciesName: String): String? {
        return try {
            val plantInfo = perenualAPI.searchPlantBySpecies(speciesName)
            plantInfo?.let { perenualAPI.getBestImageUrl(it) }
        } catch (e: Exception) {
            println("Error fetching image URL for '$speciesName': ${e.message}")
            null
        }
    }

    /**
     * Download image bytes from a URL.
     * Returns null if the download fails.
     */
    @NativeCoroutines
    suspend fun downloadImageFromUrl(imageUrl: String): ByteArray? {
        return try {
            perenualAPI.downloadImageFromUrl(imageUrl)
        } catch (e: Exception) {
            println("Error downloading image from '$imageUrl': ${e.message}")
            null
        }
    }

    fun deletePlant(plant: Plant) {
        cancelAllPlantNotifications(plant)
        plantRepository.delete(plant)
    }

    fun createWaterNotification(date: LocalDateTime, plant: Plant, image: String?, notifcationDelay: Duration) {
        val title = "Reminder: Water ${plant.name}"
        val body = "It's time to water your ${plant.name}. Make sure to do so soon so that it can stay healthy and grow"
        plant.wateringFrequency = notifcationDelay
        val delay: Long = plant.wateringFrequency.inWholeMilliseconds / 60000

        val generatedNotificationID: Uuid = Uuid.random()
        plant.wateringNotificationID = generatedNotificationID

        notificationHandler.setNotification(generatedNotificationID.toString(), title, body, date, image, delay)
    }

    fun createFertilizerNotification(date: LocalDateTime, plant: Plant, image: String?, notifcationDelay: Duration) {
        val title = "Reminder: Fertilize ${plant.name}"
        val body = "It's time to give your ${plant.name} some fertilizer. Make sure to do so soon so that it can stay healthy and grow"
        plant.fertilizingFrequency = notifcationDelay
        val delay: Long = plant.fertilizingFrequency.inWholeMilliseconds / 60000

        val generatedNotificationID: Uuid = Uuid.random()
        plant.fertilizerNotificationID = generatedNotificationID

        notificationHandler.setNotification(generatedNotificationID.toString(), title, body, date, image, delay)
    }

    fun createTrimmingNotification(date: LocalDateTime, plant: Plant, image: String?, notifcationDelay: Duration) {
        val title = "Reminder: Trim ${plant.name}"
        val body = "It's time to trim your ${plant.name}. Make sure to do so soon so that it can stay healthy and grow"
        plant.trimmingFrequency = notifcationDelay
        val delay: Long = plant.trimmingFrequency.inWholeMilliseconds / 60000

        val generatedNotificationID: Uuid = Uuid.random()
        plant.trimmingNotificationID = generatedNotificationID

        notificationHandler.setNotification(generatedNotificationID.toString(), title, body, date, image, delay)
    }

    fun cancelWateringNotification(plant: Plant) {
        if (plant.wateringNotificationID != null) {
            notificationHandler.cancelNotification(plant.wateringNotificationID.toString())
            plant.wateringNotificationID = null
        }
    }

    fun cancelFertilizerNotification(plant: Plant) {
        if (plant.fertilizerNotificationID != null) {
            notificationHandler.cancelNotification(plant.fertilizerNotificationID.toString())
            plant.fertilizerNotificationID = null
        }
    }

    fun cancelTrimmingNotification(plant: Plant) {
        if (plant.trimmingNotificationID != null) {
            notificationHandler.cancelNotification(plant.trimmingNotificationID.toString())
            plant.trimmingNotificationID = null
        }
    }

    fun cancelAllPlantNotifications(plant: Plant) {
        cancelWateringNotification(plant)
        cancelFertilizerNotification(plant)
        cancelTrimmingNotification(plant)
    }

    fun pickImage(plant: Plant) {
        viewModelScope.launch {
            val image = FileKit.openFilePicker(type = FileKitType.Image)
            image?.let { image ->
                val plantImage = imageStore.saveImage(image)
                plant.image = plantImage
                plantRepository.savePlant(plant)
            }
        }
    }

    @NativeCoroutines
    suspend fun getPlantImage(plant: Plant): ByteArray? {
        return plant.image?.imageBytes
    }

    init {
        viewModelScope.launch {
            fillPlantInfoDatabase()
        }
    }

    suspend fun fillPlantInfoDatabase() {
        val firstPlantInDatabase = plantInfoRepository.plantInfoList.first()
        if (firstPlantInDatabase.isNotEmpty()) {
            return
        }

        val popularPlantIDs = listOf(721, 607, 2774, 855, 1716, 2193, 2961, 1474, 367, 2320)

        val popularPlantsList: List<PlantInfo> = popularPlantIDs.map { id ->
            perenualAPI.searchPlantInPerenualAPI(id)
        }

        plantInfoRepository.saveMultiplePlantInfo(*popularPlantsList.toTypedArray())
    }

    suspend fun searchPlantInfoDatabase(query: String): List<PlantInfo> {
        return plantInfoRepository.searchPlantInfo(query)
    }
}
