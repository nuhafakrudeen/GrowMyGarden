import Combine
import KMPNativeCoroutinesAsync
import KMPNativeCoroutinesCombine
import Shared
import SwiftUI
import UIKit

// ===============================================================
// MARK: - Backend (Kotlin) Plant Adapter
// ===============================================================
/// Wraps the Kotlin DashboardViewModel so SwiftUI can observe it.
@MainActor
final class BackendPlantAdapter: ObservableObject {
    @Published var backendPlants: [Shared.Plant] = []

    // FIX: Track plants that are pending deletion to prevent re-adding
    @Published var pendingDeletionIDs: Set<UUID> = []

    private let dashboardViewModel: DashboardViewModel
    private var cancellables = Set<AnyCancellable>()

    init() {
        dashboardViewModel = HelperKt.getDashboardViewModel()

        let publisher: AnyPublisher<[Shared.Plant], Error> =
            createPublisher(for: dashboardViewModel.plantsStateFlow)

        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("❌ Error observing plantsStateFlow:", error)
                    }
                },
                receiveValue: { [weak self] (plants: [Shared.Plant]) in
                    guard let self = self else { return }
                    self.backendPlants = plants

                }
            )
            .store(in: &cancellables)
    }

    /// Persist a SwiftUI Plant to the backend.
    func save(uiPlant: Plant) {
        let backend = createBackendPlantFromUI(uiPlant: uiPlant)
        dashboardViewModel.savePlant(plant: backend)
    }

    /// Save a NEW plant and automatically fetch an image from Perenual API
    func saveWithAutoImage(uiPlant: Plant) {
        let backend = createBackendPlantFromUI(uiPlant: uiPlant)
        dashboardViewModel.savePlantWithAutoImage(plant: backend)
    }

    /// Helper to create a backend Plant from a SwiftUI Plant
    private func createBackendPlantFromUI(uiPlant: Plant) -> Shared.Plant {
        // 1. Calculate Milliseconds for Watering
        let waterTask = uiPlant.tasks.first(where: { $0.title == "water" })
        var waterMillis: Int64 = 0
        let waterEnabled = waterTask?.reminderEnabled ?? false

        if let waterScheduleTask = waterTask {
            if waterScheduleTask.waterMode == .timesPerDay {
                let times = max(1, waterScheduleTask.timesPerDay)
                waterMillis = Int64((24 * 60 * 60 * 1000) / times)
            } else {
                waterMillis = Int64(waterScheduleTask.frequencyDays) * 24 * 60 * 60 * 1000
            }
        }

        // 2. Calculate Milliseconds for Fertilizing
        let fertTask = uiPlant.tasks.first(where: { $0.title == "fertilize" })
        let fertMillis: Int64 = Int64(fertTask?.frequencyDays ?? 0) * 24 * 60 * 60 * 1000
        let fertEnabled = fertTask?.reminderEnabled ?? false

        // 3. Calculate Milliseconds for Trimming
        let trimTask = uiPlant.tasks.first(where: { $0.title == "trimming" })
        let trimMillis: Int64 = Int64(trimTask?.frequencyDays ?? 0) * 24 * 60 * 60 * 1000
        let trimEnabled = trimTask?.reminderEnabled ?? false

        // 4. Convert Swift Data to KotlinByteArray
        var kotlinImageBytes: KotlinByteArray?
        if let imageData = uiPlant.imageData {
            kotlinImageBytes = KotlinByteArray(size: Int32(imageData.count))
            for index in 0..<imageData.count {
                kotlinImageBytes?.set(index: Int32(index), value: Int8(bitPattern: imageData[index]))
            }
        }

        // 5. Pass everything to HelperKt
        return HelperKt.createBackendPlant(
            idString: uiPlant.id.uuidString,
            name: uiPlant.name,
            species: uiPlant.species,
            waterFreqMillis: waterMillis,
            waterEnabled: waterEnabled,
            fertFreqMillis: fertMillis,
            fertEnabled: fertEnabled,
            trimFreqMillis: trimMillis,
            trimEnabled: trimEnabled,
            imageBytes: kotlinImageBytes
        )
    }

    /// Fetch and update image for an existing plant from Perenual API
    func fetchAndUpdateImage(for uiPlant: Plant, completion: @escaping (Bool) -> Void) {
        Task {
            let uuidString = uiPlant.id.uuidString.lowercased()
            if let backend = backendPlants.first(where: {
                $0.uuid.description.lowercased() == uuidString
            }) {
                do {
                    let success: KotlinBoolean = try await asyncFunction(
                        for: dashboardViewModel.fetchAndUpdatePlantImage(plant: backend)
                    )
                    await MainActor.run {
                        completion(success.boolValue)
                    }
                } catch {
                    print("❌ Error fetching image: \(error)")
                    await MainActor.run {
                        completion(false)
                    }
                }
            } else {
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }

    func delete(uiPlant: Plant) {
        // FIX: Add to pending deletions BEFORE calling backend delete
        pendingDeletionIDs.insert(uiPlant.id)

        let uuidString = uiPlant.id.uuidString.uppercased()  // Kotlin uses HEX with dashes

        // DEBUG: Print UUIDs to see if they match
        print("🗑️ DELETE ATTEMPT:")
        print("   Swift UUID: \(uuidString)")
        print("   Backend plants count: \(backendPlants.count)")
        for backendPlant in backendPlants {
            print("   Backend UUID: \(backendPlant.uuid.description.lowercased())")
        }

        if let backend = backendPlants.first(where: {
            $0.uuid.description.uppercased() == uuidString
        }) {
            dashboardViewModel.deletePlant(plant: backend)
        }

    }
}

/// Convert a backend Shared.Plant into your local SwiftUI Plant model.
func convertBackendPlant(_ backend: Shared.Plant) -> Plant {

    // --- 1. Reconstruct Water Task ---
    let waterMillis = backend.waterMillis
    let waterEnabled = backend.wateringNotificationID != nil

    var waterTask = PlantTask(title: "water", reminderEnabled: waterEnabled, frequencyDays: 0, timesPerDay: 0, waterMode: .everyXDays)

    let oneDayMillis: Int64 = 24 * 60 * 60 * 1000

    if waterMillis > 0 {
        if waterMillis < oneDayMillis {
            waterTask.waterMode = .timesPerDay
            let times = oneDayMillis / waterMillis
            waterTask.timesPerDay = Int(times)
        } else {
            waterTask.waterMode = .everyXDays
            let days = waterMillis / oneDayMillis
            waterTask.frequencyDays = Int(days)
        }
    }

    // --- 2. Reconstruct Fertilize Task ---
    let fertMillis = backend.fertMillis
    let fertEnabled = backend.fertilizerNotificationID != nil
    let fertDays = Int(fertMillis / oneDayMillis)
    let fertTask = PlantTask(title: "fertilize", reminderEnabled: fertEnabled, frequencyDays: fertDays, timesPerDay: 0, waterMode: .everyXDays)

    // --- 3. Reconstruct Trimming Task ---
    let trimMillis = backend.trimMillis
    let trimEnabled = backend.trimmingNotificationID != nil
    let trimDays = Int(trimMillis / oneDayMillis)
    let trimTask = PlantTask(title: "trimming", reminderEnabled: trimEnabled, frequencyDays: trimDays, timesPerDay: 0, waterMode: .everyXDays)

    // --- 4. Convert Kotlin ByteArray to Swift Data ---
    var imageData: Data?
    if let plantImage = backend.image,
       let kotlinBytes = plantImage.imageBytes {
        let count = Int(kotlinBytes.size)
        var bytes = [UInt8](repeating: 0, count: count)
        for index in 0..<count {
            bytes[index] = UInt8(bitPattern: kotlinBytes.get(index: Int32(index)))
        }
        imageData = Data(bytes)
    }

    return Plant(
        id: UUID(uuidString: backend.uuid.description) ?? UUID(),
        name: backend.name,
        species: backend.species,
        imageData: imageData,
        notes: "",
        tasks: [waterTask, fertTask, trimTask]
    )
}
