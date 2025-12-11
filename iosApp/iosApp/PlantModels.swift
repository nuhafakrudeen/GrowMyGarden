import Foundation
import SwiftUI

// ===============================================================
// MARK: - DATA MODELS
// ===============================================================
enum WaterScheduleMode: String, CaseIterable, Identifiable, Hashable {
    case timesPerDay
    case everyXDays

    var id: String { rawValue }

    var label: String {
        switch self {
        case .timesPerDay: return "Per Day"
        case .everyXDays:  return "Every X Days"
        }
    }
}

struct PlantTask: Identifiable, Hashable {
    let id = UUID()
    var title: String                   // "water", "fertilize", "trimming"
    var reminderEnabled: Bool
    var frequencyDays: Int              // used for all tasks (and water when mode == .everyXDays)
    var timesPerDay: Int                // used only for water when mode == .timesPerDay
    var waterMode: WaterScheduleMode    // ignored for non-water tasks
}

// Represents a plant with its details and reminders.
struct Plant: Identifiable, Hashable {
    var id = UUID()
    var name: String                    // Display name
    var species: String                 // Plant species (required)
    var imageData: Data?                // Optional user-selected photo
    var notes: String                   // Notes entered by user
    var tasks: [PlantTask]              // List of task reminders for this plant
}

// Represents a unique species unlocked in the Plantbook
struct PlantbookEntry: Identifiable, Hashable {
    let id = UUID()
    let speciesName: String
    let fallbackImageData: Data?   // user photo for that species (if any)
}

@MainActor
final class PlantStore: ObservableObject {
    @Published var plants: [Plant] = [] // All user-added plants

    func add(_ plant: Plant) { plants.append(plant) }

    func update(_ plant: Plant) {
        if let index = plants.firstIndex(where: { $0.id == plant.id }) {
            plants[index] = plant
        }
    }
}
