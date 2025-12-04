package com.gmg.growmygarden.viewmodel

import com.gmg.growmygarden.NotificationHandler
import com.gmg.growmygarden.auth.UserManager
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
import io.github.vinceglb.filekit.readBytes
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

    fun deletePlant(plant: Plant) {
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
        return plant.image?.hqFile?.readBytes()
    }
    init {
        viewModelScope.launch {
            fillPlantInfoDatabase()
        }
    }

    suspend fun fillPlantInfoDatabase() {
        val firstPlantInDatabase = plantInfoRepository.plantInfoList.first()
        if (firstPlantInDatabase.isEmpty()) {
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
