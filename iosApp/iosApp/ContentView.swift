import SwiftUI
import PhotosUI
import Photos            // 👈 Added to request photo permissions explicitly
import UserNotifications

// Simple local notifications manager
enum NotificationManager {
    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus != .authorized else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        }
    }
    
    static func scheduleRepeating(taskTitle: String, plantName: String, identifier: String, everyDays: Int) {
        // Cancel any previous with same identifier first
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        let content = UNMutableNotificationContent()
        content.title = "Time to \(taskTitle)"
        content.body = "Remember to \(taskTitle) your \(plantName)"
        content.sound = .default
        
        // Repeat every N days from now (simple & reliable)
        let seconds = max(60, everyDays * 24 * 60 * 60) // must be >= 60 to allow repeats
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: true)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    static func cancel(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

// 👇 New: Explicit photo permission helper
enum PhotoPermissionManager {
    static func requestPhotoAccess(completion: @escaping (Bool) -> Void = { _ in }) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                completion(status == .authorized || status == .limited)
            }
        }
    }
}

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
    @State private var selectedTab: AppTab = .home
    
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
                    
                    ScrollView {
                        LazyVStack(spacing: 18) {
                            ForEach($store.plants) { $plant in
                                PlantCard(
                                    plant: $plant,
                                    onDelete: { id in
                                        store.plants.removeAll { $0.id == id }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 120) // height ≈ your bottom bar
                    }
                case .search:
                    Spacer(minLength: 0)
                case .community:
                    Spacer(minLength: 0)
                case .plantbook:
                    Spacer(minLength: 0)
                }
                
                RoundedBottomBar(selected: $selectedTab)
            }
        }
        .sheet(isPresented: $isAddingPlant) {
            AddPlantSheet(isPresented: $isAddingPlant) { newPlant in
                store.add(newPlant)
            }
        }
    }
}

// ===============================================================
// MARK: - PLANT CARD
// ===============================================================
struct PlantCard: View {
    @Binding var plant: Plant
    var onDelete: (UUID) -> Void = { _ in }
    @State private var showReminders = false
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // ===== HEADER ROW =====
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(plant.name.isEmpty ? "Plant Name" : plant.name)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.primary)

                        Spacer()

                        Button("Edit") { isEditing = true }
                            .font(.system(size: 14))
                            .foregroundColor(Color("DarkGreen"))
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                            .padding(.trailing, 8)
                    }
                }
                .padding(.vertical, 8)
                .padding(.leading, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if let data = plant.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 55)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 6)

            // ===== REMINDERS BUTTON =====
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    showReminders.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showReminders ? "chevron.up" : "chevron.down")
                    Text("reminders")
                    Spacer()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
            }
            .buttonStyle(.plain)

            // ===== DROPDOWN =====
            if showReminders {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Spacer()
                        Text("Enable Notifications")
                            .font(.headline)
                            .padding(.bottom, 2)
                    }

                    // 👇 For each reminder
                    ForEach($plant.tasks) { $task in
                        ReminderRow(task: $task, plant: plant)
                            .padding(.vertical, 6)
                    }

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
                .transition(.opacity)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.18), lineWidth: 2)
        )
        .sheet(isPresented: $isEditing) {
            EditPlantSheet(isPresented: $isEditing, plant: $plant, onDelete: { onDelete(plant.id) })
        }
    }
}


private struct ReminderRow: View {
    @Binding var task: PlantTask
    let plant: Plant

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("-")
                    Text(task.title.capitalized)
                        .font(.system(size: 18, weight: .semibold))
                }
                subLabel
            }

            Spacer()

            Toggle("", isOn: $task.reminderEnabled)
                .labelsHidden()
                .onChange(of: task.reminderEnabled) { isOn in
                    handleToggle(isOn: isOn)
                }
        }
    }

    private var subLabel: some View {
        switch task.title.lowercased() {
        case "water":
            return Text("Every 3 days recommended")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 16)
                .eraseToAnyView()
        case "fertilize":
            return Text("Every 30 days recommended")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 16)
                .eraseToAnyView()
        default:
            return EmptyView().eraseToAnyView()
        }
    }

    private func handleToggle(isOn: Bool) {
        // 👇 Ask for permissions when enabling notifications for the first time
        if isOn {
            NotificationManager.requestAuthorizationIfNeeded()
            PhotoPermissionManager.requestPhotoAccess()
        }

        // Then schedule or cancel reminders
        let id = "\(plant.id.uuidString)::\(task.title.lowercased())"
        let days = (task.title.lowercased() == "water") ? 3 : 30

        if isOn {
            NotificationManager.scheduleRepeating(
                taskTitle: task.title,
                plantName: plant.name.isEmpty ? "your plant" : plant.name,
                identifier: id,
                everyDays: days
            )
        } else {
            NotificationManager.cancel(identifier: id)
        }
    }
}

private extension View {
    func eraseToAnyView() -> AnyView { AnyView(self) }
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
            ZStack{
                LinearGradient(
                    colors: [Color("LightGreen"), Color("SoftCream")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
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
                .scrollContentBackground(.hidden)  // 👈 hides white form background
                .background(Color.clear)
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
// MARK: - EDIT PLANT SHEET
// ===============================================================

struct EditPlantSheet: View {
    @Binding var isPresented: Bool
    @Binding var plant: Plant
    var onDelete: () -> Void

    @State private var newName: String = ""
    @State private var newNotes: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var newImageData: Data?
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            // 🌿 Gradient background matching home page
            LinearGradient(
                colors: [Color("LightGreen"), Color("SoftCream")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack {
                    Button("Cancel") { isPresented = false }
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color("DarkGreen"))

                    Spacer()

                    Text("Edit Plant")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("DarkGreen"))

                    Spacer()

                    Button("Save") {
                        if !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                            plant.name = newName.trimmingCharacters(in: .whitespaces)
                        }
                        if !newNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            plant.notes = newNotes
                        }
                        if let data = newImageData {
                            plant.imageData = data
                        }
                        isPresented = false
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("DarkGreen"))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView {
                    VStack(spacing: 24) {

                        // 🪴 Photo picker section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Photo")
                                .font(.headline)
                                .foregroundColor(Color("DarkGreen"))

                            HStack(spacing: 16) {
                                Group {
                                    if let newImageData, let ui = UIImage(data: newImageData) {
                                        Image(uiImage: ui)
                                            .resizable()
                                            .scaledToFill()
                                    } else if let data = plant.imageData, let ui = UIImage(data: data) {
                                        Image(uiImage: ui)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color("DarkGreen").opacity(0.25), lineWidth: 1.5)
                                                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.6)))
                                            Image(systemName: "photo.on.rectangle")
                                                .font(.title3)
                                                .foregroundColor(Color("DarkGreen").opacity(0.8))
                                        }
                                    }
                                }
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    Label("Choose Photo", systemImage: "photo")
                                        .foregroundColor(Color("DarkGreen"))
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .onChange(of: selectedPhotoItem) { item in
                                    Task {
                                        if let data = try? await item?.loadTransferable(type: Data.self) {
                                            newImageData = data
                                        }
                                    }
                                }
                            }
                        }

                        // 🌱 Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plant Name")
                                .font(.headline)
                                .foregroundColor(Color("DarkGreen"))

                            TextField("Enter new name", text: $newName)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.85))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color("DarkGreen").opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }

                    
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(Color("DarkGreen"))

                            TextEditor(text: $newNotes)
                                .frame(minHeight: 140)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.85))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color("DarkGreen").opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .scrollIndicators(.hidden)
                }

                Spacer()

                // 🗑️ Custom trash + popup overlay
                VStack(spacing: 12) {
                    if showDeleteConfirm {
                        VStack(spacing: 12) {
                            Text("Delete this plant?")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            HStack(spacing: 28) {
                                Button("Cancel") {
                                    withAnimation(.easeInOut) { showDeleteConfirm = false }
                                }
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))

                                Button("Delete", role: .destructive) {
                                    onDelete()
                                    isPresented = false
                                }
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.red.opacity(0.9))
                            }
                        }
                        .frame(width: 320)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color("DarkGreen"))
                                .shadow(color: Color("DarkGreen").opacity(0.35), radius: 10, y: 4)
                        )
                        .padding(.bottom, 70)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDeleteConfirm.toggle()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 54, height: 54)
                                .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                            Image(systemName: "trash")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.9), value: showDeleteConfirm)
            }
        }
        .onAppear {
            newName = plant.name
            newNotes = plant.notes
        }
    }
}

//MARK: - BOTTOM PAGES
enum AppTab: Hashable{
    case home, search, community, plantbook
}

// ===============================================================
// MARK: - HOME HEADER (Floating Capsule)
// ===============================================================

struct HomeHeader: View {
    let count: Int
    let onAdd: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            // Edge-to-edge background that hugs top/left/right
            Rectangle()
                .fill(Color("DarkGreen").opacity(0.12))
                .overlay(
                    Rectangle()
                        .stroke(Color("DarkGreen").opacity(0.18), lineWidth: 1)
                )
                .ignoresSafeArea(edges: .top)       // cover behind status bar
                .frame(maxWidth: .infinity)
                .frame(height: 110)                 // header height

            // Content stays in the same place with 16pt insets
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(Color("DarkGreen"))
                            .font(.system(size: 20, weight: .bold))
                            .accessibilityHidden(true)
                        
                        Text("Your Plants")
                            .font(.system(size: 35, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("DarkGreen"))
                    }

                    Text("\(count) \(count == 1 ? "plant" : "plants")")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color("DarkGreen"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.85))
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(Color("DarkGreen").opacity(0.2), lineWidth: 1)
                                )
                        )
                        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: count)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: onAdd) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.95))
                            .overlay(
                                Circle().stroke(Color("DarkGreen").opacity(0.2), lineWidth: 1)
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: Color("DarkGreen").opacity(0.18), radius: 8, y: 3)

                        Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 41, weight: .semibold))
                                        .foregroundColor(Color("DarkGreen"))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add Plant")
            }
            .padding(.horizontal, 35)
            .padding(.top, 16)
        }
        // No outer horizontal padding — lets the background hit the edges
        // Keep a small spacer below the header in your parent if needed.
    }
}


// ===============================================================
// MARK: - BOTTOM BAR COMPONENTS
// ===============================================================

struct RoundedBottomBar: View {
    @Binding var selected: AppTab

    var body: some View {
        ZStack {
            // Floating dark-green capsule
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color("DarkGreen").opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color("DarkGreen").opacity(0.35), radius: 10, y: 6)
                .frame(height: 90)
                .frame(width: 370)
                .padding(.horizontal, 28)
                .padding(.bottom, 6)

            HStack(spacing: 28) {
                TabButton(
                    systemName: "house.fill",
                    isActive: selected == .home,
                    label: "Home",
                    selected: $selected,
                    tab: .home
                )
                TabButton(
                    systemName: "magnifyingglass",
                    isActive: selected == .search,
                    label: "Search",
                    selected: $selected,
                    tab: .search
                )
                TabButton(
                    systemName: "hand.raised.fill",
                    isActive: selected == .community,
                    label: "Community",
                    selected: $selected,
                    tab: .community
                )
                TabButton(
                    systemName: "book.fill",
                    isActive: selected == .plantbook,
                    label: "Plantbook",
                    selected: $selected,
                    tab: .plantbook
                )
            }
            .padding(.bottom, 2)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct TabButton: View {
    let systemName: String
    let isActive: Bool
    let label: String
    @Binding var selected: AppTab
    let tab: AppTab

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.12)) {
                selected = tab
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isActive ? Color.white.opacity(0.16) : Color.clear)
                Circle()
                    .stroke(isActive ? Color.white.opacity(0.35)
                                     : Color.white.opacity(0.18), lineWidth: 1.5)
            }
            .frame(width: 58, height: 58)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isActive ? .white : .white.opacity(0.8))
                    .scaleEffect(isActive ? 1.12 : 1.0)
                    .shadow(color: isActive ? .white.opacity(0.25) : .clear, radius: 6)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
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
