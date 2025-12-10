import KMPNativeCoroutinesAsync
import Shared
import SwiftUI
import PhotosUI
import UIKit

// ===============================================================
// MARK: - SEARCH SERVICE (Backend placeholder)
// ===============================================================

struct SearchResult: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String      // Scientific name
    let detail: String        // Family

    // Care schedule info
    let wateringInfo: String
    let sunlightInfo: String
    let trimmingInfo: String
    let fertilizingInfo: String

    // Image URL from Perenual API (NEW)
    let imageUrl: String?

    // Original Kotlin object for passing to detail views
    let originalData: Shared.PlantInfo?
}

// 2. ViewModel to handle the Kotlin interaction
@MainActor
class SearchViewModel: ObservableObject {
    @Published var results: [SearchResult] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let repository: PlantInfoRepository = HelperKt.getPlantInfoRepository()

    func performSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            self.results = []
            return
        }

        self.isLoading = true
        self.errorMessage = nil

        do {
            // Call the Kotlin suspend function
            let result = try await repository.searchRemotePlants(query: trimmed)
            let kotlinResults = result as? [Shared.PlantInfo] ?? []

            print("🌿 API Results: \(kotlinResults.count) plants found.")

            if let first = kotlinResults.first {
                print("🔍 First result: \(first.name ?? "nil"), watering=\(first.wateringDescription)")
            }

            // Map Kotlin PlantInfo to Swift SearchResult
            self.results = kotlinResults.map { info in
                let name = info.name ?? "Unknown Plant"
                let sciName = info.scientificName?.first ?? ""
                let family = info.family ?? ""

                // Use the computed properties from Kotlin
                let watering = info.wateringDescription
                let sunlight = info.sunlightDescription
                let trimming = info.trimmingDescription
                let fertilizing = info.fertilizingEstimate

                // Get the best image URL from PlantInfo (NEW)
                let imageUrl = info.image?.mediumUrl
                    ?? info.image?.regularUrl
                    ?? info.image?.smallUrl
                    ?? info.image?.thumbnail
                    ?? info.image?.originalUrl

                return SearchResult(
                    title: name,
                    subtitle: sciName,
                    detail: family,
                    wateringInfo: watering,
                    sunlightInfo: sunlight,
                    trimmingInfo: trimming,
                    fertilizingInfo: fertilizing,
                    imageUrl: imageUrl,  // NEW
                    originalData: info
                )
            }
        } catch {
            print("❌ Search Error: \(error)")
            self.errorMessage = "Failed to search database."
            self.results = []
        }

        self.isLoading = false
    }
}

// Helper to normalize PhotosPicker images into JPEG Data
func loadImageData(from item: PhotosPickerItem?) async -> Data? {
    guard let item = item else { return nil }

    // Try to load the raw Data (Transferable)
    if let rawData = try? await item.loadTransferable(type: Data.self),
       let uiImage = UIImage(data: rawData),
       let jpegData = uiImage.jpegData(compressionQuality: 0.9) {
        return jpegData
    }

    return nil
}
