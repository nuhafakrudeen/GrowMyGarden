import Photos
import PhotosUI
import Shared
import SwiftUI

// ===============================================================
// MARK: - MAIN SCREEN
// ===============================================================

struct PlantsHomeView: View {
    @StateObject private var store = PlantStore()
    @StateObject private var backendAdapter = BackendPlantAdapter()
    @State private var isAddingPlant = false
    @State private var selectedTab: AppTab = .home

    // All unique species from the user's plants
    private var plantbookEntries: [PlantbookEntry] {
        let groups = Dictionary(grouping: store.plants) { plant in
            plant.species
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        }

        return groups.values.compactMap { plantsForSpecies in
            guard let first = plantsForSpecies.first else { return nil }

            let display = first.species.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = display.isEmpty ? "Unknown Species" : display

            // use the first plant's image as fallback (if it has one)
            return PlantbookEntry(
                speciesName: name,
                fallbackImageData: first.imageData
            )
        }
        .sorted { $0.speciesName.localizedCaseInsensitiveCompare($1.speciesName) == .orderedAscending }
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color("LightGreen"), Color("SoftCream")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                switch selectedTab {
                case .home:
                    HomeHeader(count: store.plants.count) {
                        isAddingPlant = true
                    }

                    if store.plants.isEmpty {
                        VStack(spacing: 18) {
                            Image(systemName: "leaf.circle")
                                .font(.system(size: 60, weight: .regular))
                                .foregroundColor(Color("DarkGreen").opacity(0.9))

                            Text("No plants yet")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Color("DarkGreen"))

                            Text("Add a plant using the \"+\" on the top right to start your plant care journey!")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color("DarkGreen").opacity(0.8))
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 18) {
                                // FIXED: Use ForEach with id and PlantCardWrapper
                                ForEach(store.plants, id: \.id) { plant in
                                    PlantCardWrapper(
                                        plant: plant,
                                        onUpdate: { updatedPlant in
                                            // Update local store
                                            if let idx = store.plants.firstIndex(where: { $0.id == updatedPlant.id }) {
                                                store.plants[idx] = updatedPlant
                                            }
                                            // Save to backend
                                            backendAdapter.save(uiPlant: updatedPlant)
                                        },
                                        onDelete: { id in
                                            // Tell backend to delete (marks as pending)
                                            if let uiPlant = store.plants.first(where: { $0.id == id }) {
                                                backendAdapter.delete(uiPlant: uiPlant)
                                            }
                                            // Remove from local store
                                            withAnimation {
                                                store.plants.removeAll { $0.id == id }
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 120)
                        }
                    }

                case .search:
                    SearchView()

                case .plantbook:
                    PlantbookView(entries: plantbookEntries)

                case .profile:
                    ProfileView()
                }

                RoundedBottomBar(selected: $selectedTab)
            }
        }
        .sheet(isPresented: $isAddingPlant) {
            AddPlantSheet(isPresented: $isAddingPlant) { newPlant in
                // 1) Local UI update
                store.add(newPlant)
                // 2) Persist to Kotlin backend WITH auto image fetching
                backendAdapter.saveWithAutoImage(uiPlant: newPlant)
            }
        }
        .onReceive(backendAdapter.$backendPlants) { backendPlants in
            // Build map of existing plants by UUID
            var existingMap = [UUID: Plant]()
            for plant in store.plants {
                existingMap[plant.id] = plant
            }

            // Get the set of IDs that are pending deletion
            let pendingDeletions = backendAdapter.pendingDeletionIDs

            // Build merged list, excluding plants pending deletion
            let merged: [Plant] = backendPlants.compactMap { backendPlant -> Plant? in
                guard let uuid = UUID(uuidString: backendPlant.uuid.description) else {
                    return nil
                }

                // Skip plants that are pending deletion
                if pendingDeletions.contains(uuid) {
                    return nil
                }

                if var existing = existingMap[uuid] {
                    // Keep existing plant but update image if backend has one and local doesn't
                    if existing.imageData == nil,
                       let plantImage = backendPlant.image,
                       let kotlinBytes = plantImage.imageBytes {
                        let count = Int(kotlinBytes.size)
                        var bytes = [UInt8](repeating: 0, count: count)
                        for index in 0..<count {
                            bytes[index] = UInt8(bitPattern: kotlinBytes.get(index: Int32(index)))
                        }
                        existing.imageData = Data(bytes)
                    }
                    return existing
                } else {
                    // New plant from backend
                    return convertBackendPlant(backendPlant)
                }
            }

            // Only update if there's a real change
            let currentIDs = Set(store.plants.map { $0.id })
            let mergedIDs = Set(merged.map { $0.id })

            if currentIDs != mergedIDs {
                store.plants = merged
            } else {
                // Check for image updates only
                for (index, plant) in store.plants.enumerated() {
                    if let mergedPlant = merged.first(where: { $0.id == plant.id }),
                       plant.imageData == nil && mergedPlant.imageData != nil {
                        store.plants[index].imageData = mergedPlant.imageData
                    }
                }
            }
        }
    }
}
