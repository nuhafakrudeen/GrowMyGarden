package com.gmg.growmygarden.viewmodel

import com.gmg.growmygarden.data.source.Plant
import com.gmg.growmygarden.data.source.PlantImageStore
import com.gmg.growmygarden.data.source.PlantRepository
import com.rickclephas.kmp.nativecoroutines.NativeCoroutinesState
import com.rickclephas.kmp.observableviewmodel.ViewModel
import com.rickclephas.kmp.observableviewmodel.launch
import com.rickclephas.kmp.observableviewmodel.stateIn
import io.github.vinceglb.filekit.FileKit
import io.github.vinceglb.filekit.dialogs.FileKitType
import io.github.vinceglb.filekit.dialogs.openFilePicker
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlin.collections.listOf

class DashboardViewModel(
    private val plantRepository: PlantRepository,
    private val imageStore: PlantImageStore,
) : ViewModel() {

    @NativeCoroutinesState
    val plantsState: StateFlow<List<Plant>> = plantRepository.plants.stateIn(
        viewModelScope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000L),
        initialValue = listOf<Plant>(),
    )

    fun savePlant(plant: Plant) {
        plantRepository.savePlant(plant)
    }

    fun deletePlant(plant: Plant) {
        plantRepository.delete(plant)
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
}
