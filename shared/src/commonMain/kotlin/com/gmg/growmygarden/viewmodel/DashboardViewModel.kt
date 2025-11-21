package com.gmg.growmygarden.viewmodel

import com.gmg.growmygarden.NotificationHandler
import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.data.source.PlantImageStore
import com.gmg.growmygarden.data.source.PlantInfo
import com.gmg.growmygarden.data.source.PlantInfoRepository
import com.gmg.growmygarden.data.source.PlantRepository
import com.gmg.growmygarden.network.PerenualApi
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
import kotlin.uuid.Uuid

class DashboardViewModel(
    private val plantRepository: PlantRepository,
    private val imageStore: PlantImageStore,
    private val notificationHandler: NotificationHandler,
    private val perenualAPI: PerenualApi,
    private val plantInfoRepository: PlantInfoRepository,
) : ViewModel() {

    @NativeCoroutinesState
    val plantsState: StateFlow<List<Plant>> = plantRepository.plants.stateIn(
        viewModelScope,
        started = SharingStarted.WhileSubscribed(5000L),
        initialValue = listOf<Plant>(),
    )

    fun savePlant(plant: Plant) {
        plantRepository.savePlant(plant)
    }

    fun deletePlant(plant: Plant) {
        plantRepository.delete(plant)
    }

    fun createWaterNotification(date: LocalDateTime, plant: Plant, image: String?) {
        val title = "Reminder: Water ${plant.name}"
        val body = "It's time to water your ${plant.name}. Make sure to do so soon so that it can stay healthy and grow"
        val delay: Long = plant.wateringFrequency.inWholeMilliseconds / 60000

        val generatedNotificationID: Uuid = Uuid.random()
        plant.wateringNotificationID = generatedNotificationID

        notificationHandler.setNotification(generatedNotificationID.toString(), title, body, date, image, delay)
    }

    fun createFertilizerNotification(date: LocalDateTime, plant: Plant, image: String?) {
        val title = "Reminder: Fertilize ${plant.name}"
        val body = "It's time to give your ${plant.name} some fertilizer. Make sure to do so soon so that it can stay healthy and grow"
        val delay: Long = plant.fertilizingFrequency.inWholeMilliseconds / 60000

        val generatedNotificationID: Uuid = Uuid.random()
        plant.fertilizerNotificationID = generatedNotificationID

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

    fun cancelAllPlantNotifications(plant: Plant) {
        cancelWateringNotification(plant)
        cancelFertilizerNotification(plant)
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

    suspend fun fillPlantInfoDatabase() {
        val firstPlantInDatabase = plantInfoRepository.plantInfoList.first()
        if (firstPlantInDatabase.isEmpty()) {
            return
        }

        val popularPlantIDs = listOf(721, 3384, 7168)

        val popularPlantsList: List<PlantInfo> = popularPlantIDs.map { id ->
            perenualAPI.searchPlantInTrefleAPI(id)
        }

        plantInfoRepository.saveMultiplePlantInfo(*popularPlantsList.toTypedArray())
    }


}
