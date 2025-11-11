package com.gmg.growmygarden.viewmodel

import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.data.source.PlantRepository
import com.gmg.growmygarden.NotificationHandler
import com.rickclephas.kmp.nativecoroutines.NativeCoroutinesState
import com.rickclephas.kmp.observableviewmodel.ViewModel
import com.rickclephas.kmp.observableviewmodel.stateIn
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlin.collections.listOf
import kotlinx.coroutines.flow.update
import kotlinx.datetime.LocalDateTime
import kotlin.uuid.Uuid

class DashboardViewModel(
    private val plantRepository: PlantRepository,
) : ViewModel() {

    @NativeCoroutinesState
    val plantsState: StateFlow<List<Plant>> = plantRepository.plants.stateIn(
        viewModelScope,
        started = SharingStarted.WhileSubscribed(5000L),
        initialValue = listOf<Plant>(),
    )

    val commandLog = MutableStateFlow<String>("None")
    val commandHistory: StateFlow<String> get() = commandLog

    val currentlyUsedNotificationIDs: MutableSet<String> = mutableSetOf()

    fun savePlant(plant: Plant) {
        plantRepository.savePlant(plant)
    }

    fun deletePlant(plant: Plant) {
        plantRepository.delete(plant)
    }

    fun createWaterNotification(date: LocalDateTime, plant: Plant, image: String?)
    {
        val title = "Reminder: Water ${plant.name}"
        val body = "It's time to water your ${plant.name}. Make sure to do so soon so that it can stay healthy and grow"
        val delay : Long = plant.wateringFrequency.inWholeMilliseconds / 60000
        var generatedNotificationID : String

        while(true)
        {
            generatedNotificationID = Uuid.random().toString()
            if(!currentlyUsedNotificationIDs.contains(generatedNotificationID))
            {
                currentlyUsedNotificationIDs.add(generatedNotificationID)
                plant.wateringNotificationID = generatedNotificationID
                break
            }
        }

        NotificationHandler.setNotification(generatedNotificationID, title, body, date, image, delay)
        commandLog.update { "Setting water notification for ${plant.name}" }
    }

    fun createFertilizerNotification(id: String, date: LocalDateTime, plant: Plant, image: String?)
    {
        val title = "Reminder: Fertilize ${plant.name}"
        val body = "It's time to give your ${plant.name} some fertilizer. Make sure to do so soon so that it can stay healthy and grow"
        val delay : Long = plant.fertilizingFrequency.inWholeMilliseconds / 60000

        var generatedNotificationID : String

        while(true)
        {
            generatedNotificationID = Uuid.random().toString()
            if(!currentlyUsedNotificationIDs.contains(generatedNotificationID))
            {
                currentlyUsedNotificationIDs.add(generatedNotificationID)
                plant.fertilizerNotificationID = generatedNotificationID
                break
            }
        }

        NotificationHandler.setNotification(id, title, body, date, image, delay)
        commandLog.update { "Setting fertilizer notification for ${plant.name}" }

    }

    fun cancelWateringNotification(plant: Plant)
    {
        if(!plant.wateringNotificationID.isEmpty())
        {
            NotificationHandler.cancelNotification(plant.wateringNotificationID)
            currentlyUsedNotificationIDs.remove(plant.wateringNotificationID)
            commandLog.update { "Cancelling water notification for ${plant.name}" }
        }
        else
        {
            commandLog.update { "Failed to cancel water notification: No ID found" }
        }
    }

    fun cancelFertilizerNotification(plant: Plant)
    {
        if(!plant.fertilizerNotificationID.isEmpty())
        {
            NotificationHandler.cancelNotification(plant.fertilizerNotificationID)
            currentlyUsedNotificationIDs.remove(plant.fertilizerNotificationID)
            commandLog.update { "Cancelling fertilizer notification for ${plant.name}" }
        }
        else
        {
            commandLog.update { "Failed to cancel fertilizer notification: No ID found" }
        }
    }

    fun cancelAllPlantNotifications(plant: Plant)
    {
        cancelWateringNotification(plant)
        cancelFertilizerNotification(plant)
    }
    

}
