import SwiftUI
import PhotosUI

// ===============================================================
// MARK: - DATA MODELS
// ===============================================================

/// Represents a single plant-related reminder task (like "water" or "fertilize").
struct PlantTask: Identifiable, Hashable {
    let id = UUID()                     // Unique ID for SwiftUI’s list diffing
    var title: String                   // reminder name
    var reminderEnabled: Bool           // bool for if the user enabled the reminder toggle
}

/// Represents a plant with its details and reminders.
struct Plant: Identifiable, Hashable {
    let id = UUID()
    var name: String                    // Display name
    var imageData: Data?                // Optional user-selected photo
    var notes: String                   // Notes entered by user
    var tasks: [PlantTask]              // List of task reminders for this plant
}

/// Observable data store (temporary in-memory database).
final class PlantStore: ObservableObject {
    @Published var plants: [Plant] = [] // All user-added plants
    
    func add(_ plant: Plant) { plants.append(plant) }
    
    func update(_ plant: Plant) {
        if let i = plants.firstIndex(where: { $0.id == plant.id }) {
            plants[i] = plant
        }
    }
}

// ===============================================================
// MARK: - MAIN SCREEN
// ===============================================================

struct PlantsHomeView: View {
    @StateObject private var store = PlantStore()
    @State private var isAddingPlant = false
    
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
                header
                Divider().padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 18) {
                        ForEach($store.plants) { $plant in
                            PlantCard(plant: $plant)
                        }
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                
                RoundedBottomBar()
            }
        }
        .sheet(isPresented: $isAddingPlant) {
            AddPlantSheet(isPresented: $isAddingPlant) { newPlant in
                store.add(newPlant)
            }
        }
    }

    
    // MARK: - Header component
    private var header: some View {
        ZStack{
            HStack {
                Text("Your Plants")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(1.5)
                
                Spacer()
                
                // “+” button opens AddPlantSheet
                Button { isAddingPlant = true } label: {
                    ZStack {
                        Circle().stroke(Color.primary.opacity(0.25), lineWidth: 2)
                            .frame(width: 40, height: 40)
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add Plant")
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
}

// ===============================================================
// MARK: - PLANT CARD
// ===============================================================

struct PlantCard: View {
    @Binding var plant: Plant
    @State private var showReminders = false // For dropdown animation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ---------------- HEADER ROW ----------------
            HStack(spacing: 12) {
                Text(plant.name.isEmpty ? "Plant Name" : plant.name)
                    .font(.system(size: 24, weight: .heavy))
                    .padding(.vertical, 8)
                    .padding(.leading, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Group {
                    if let data = plant.imageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.25), lineWidth: 2)
                            .overlay(
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                .frame(width: 60, height: 55)
            }
            .padding(.horizontal, 6)
            
            // ---------------- REMINDERS BUTTON ----------------
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    showReminders.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showReminders ? "chevron.up" : "chevron.down")
                    Text("Reminders")
                    Spacer()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
            }
            .buttonStyle(.plain)
            
            // ---------------- DROPDOWN CONTENT ----------------
            if showReminders {
                VStack(alignment: .leading, spacing: 8) {
                    // ✅ NEW: Section title for the switches
                    HStack {
                        Spacer() // pushes the text to the far right
                        Text("Enable Notifications")
                            .font(.headline)
                            .padding(.bottom, 2)
                    }
                    
                    // Each To-Do item with a right-side toggle
                    ForEach($plant.tasks) { $task in
                        HStack {
                            // Left side: task name (e.g. “water”)
                            HStack(spacing: 8) {
                                Text("-")
                                Text(task.title)
                            }
                            .font(.system(size: 18, weight: .semibold))
                            
                            Spacer()
                            
                            // Right side: toggle switch
                            Toggle("", isOn: $task.reminderEnabled)
                                .labelsHidden()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Optional notes section
                    if !plant.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Notes:")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                        Text(plant.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.15), lineWidth: 2)
                )
                .padding(.horizontal, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.18), lineWidth: 2)
        )
    }
}

// ===============================================================
// MARK: - ADD PLANT SHEET (NO SPECIES OR CARE)
// ===============================================================

struct AddPlantSheet: View {
    @Binding var isPresented: Bool
    var onSave: (Plant) -> Void
    
    @State private var name = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var notes = ""
    
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    
    var body: some View {
        NavigationStack {
            Form {
                // ---- PHOTO PICKER ----
                Section("Photo") {
                    HStack(spacing: 16) {
                        Group {
                            if let imageData, let ui = UIImage(data: imageData) {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.quaternary, lineWidth: 1.5)
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Choose Photo", systemImage: "photo")
                        }
                        .onChange(of: selectedPhotoItem) { item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self) {
                                    imageData = data
                                }
                            }
                        }
                    }
                }
                
                // ---- NAME ----
                Section("Basics") {
                    TextField("Plant name (required)", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                
                // ---- NOTES ----
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.quaternary, lineWidth: 1)
                        )
                        .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Create new plant with default tasks
                        let defaultTasks = [
                            PlantTask(title: "water", reminderEnabled: false),
                            PlantTask(title: "fertilize", reminderEnabled: false)
                        ]
                        let plant = Plant(
                            name: name.trimmingCharacters(in: .whitespaces),
                            imageData: imageData,
                            notes: notes,
                            tasks: defaultTasks
                        )
                        onSave(plant)
                        isPresented = false
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

// ===============================================================
// MARK: - BOTTOM BAR COMPONENTS
// ===============================================================

struct RoundedBottomBar: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(.systemGray6))
                .frame(height: 84)
                .shadow(color: .black.opacity(0.06), radius: 6, y: -2)
                .padding(.horizontal, 10)
            HStack(spacing: 28) {
                CircleIcon(selected: true, systemName: "house.fill")
                CircleIcon(systemName: "magnifyingglass")
                CircleIcon(systemName: "hand.raised.fill")
                CircleIcon(systemName: "book")
            }
            .padding(.bottom, 6)
        }
        .padding(.bottom, 8)
        .ignoresSafeArea(edges: .bottom)
    }
}

/// Individual circular icon for the bottom bar
struct CircleIcon: View {
    var selected = false
    let systemName: String
    var body: some View {
        ZStack {
            Circle()
                .fill(selected ? Color.green.opacity(0.2) : Color.clear)
                .overlay(Circle().stroke(Color.primary.opacity(0.25), lineWidth: 2))
                .frame(width: 64, height: 64)
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .bold))
        }
        .contentShape(Circle())
    }
}

// ===============================================================
// MARK: - BINDING PREVIEW HELPER
// ===============================================================

struct BindingPreview<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content
    
    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(wrappedValue: initialValue)
        self.content = content
    }
    
    var body: some View { content($value) }
}

// ===============================================================
// MARK: - PREVIEWS
// ===============================================================

#Preview("Main") {
    PlantsHomeView()
}

#Preview("Expanded Card") {
    BindingPreview(
        Plant(
            name: "Monstera",
            imageData: nil,
            notes: "Keep near indirect sunlight.",
            tasks: [
                PlantTask(title: "water", reminderEnabled: true),
                PlantTask(title: "fertilize", reminderEnabled: false)
            ]
        )
    ) { $plant in
        PlantCard(plant: $plant)
            .padding()
    }
}
