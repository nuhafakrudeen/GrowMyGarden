import FirebaseAuth
import Photos
import PhotosUI
import SwiftUI
import UIKit

// MARK: - BOTTOM PAGES
enum AppTab: Hashable {
    case home, search, plantbook, profile
}

// ===============================================================
// MARK: - HOME HEADER
// ===============================================================

struct HomeHeader: View {
    let count: Int
    let onAdd: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Color("DarkGreen").opacity(0.12))
                .overlay(
                    Rectangle()
                        .stroke(Color("DarkGreen").opacity(0.18), lineWidth: 1)
                )
                .ignoresSafeArea(edges: .top)
                .frame(maxWidth: .infinity)
                .frame(height: 110)

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
    }
}

// ===============================================================
// MARK: - BOTTOM BAR COMPONENTS
// ===============================================================

struct RoundedBottomBar: View {
    @Binding var selected: AppTab

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color("DarkGreen").opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color("DarkGreen").opacity(0.35), radius: 10, y: 6)
                .frame(height: 90)
                .frame(width: 330)
                .padding(.horizontal, 28)
                .padding(.bottom, 6)

            HStack(spacing: 19) {
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
                    systemName: "book.fill",
                    isActive: selected == .plantbook,
                    label: "Plantbook",
                    selected: $selected,
                    tab: .plantbook
                )
                TabButton(
                    systemName: "person.crop.circle.fill",
                    isActive: selected == .profile,
                    label: "Profile",
                    selected: $selected,
                    tab: .profile
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

struct PlantCardWrapper: View {
    let plant: Plant
    let onUpdate: (Plant) -> Void
    let onDelete: (UUID) -> Void

    @State private var localPlant: Plant

    init(plant: Plant, onUpdate: @escaping (Plant) -> Void, onDelete: @escaping (UUID) -> Void) {
        self.plant = plant
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._localPlant = State(initialValue: plant)
    }

    var body: some View {
        PlantCard(
            plant: $localPlant,
            onSave: { updated in
                onUpdate(updated)
            },
            onDelete: onDelete
        )
        .onChange(of: plant) { newPlant in
            // Sync if parent data changes (e.g., image updated from backend)
            localPlant = newPlant
        }
    }
}
// ===============================================================
// MARK: - PROFILE VIEW
// ===============================================================
struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager

    // Firebase user shortcut
    private var user: FirebaseAuth.User? {
        Auth.auth().currentUser
    }

    // Editable state
    @State private var editableName: String = ""
    @State private var isSavingName = false
    @State private var nameSaveError: String?

    // Avatar storage
    @AppStorage("gmg.profileImageData") private var profileImageData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showPhotoDeniedAlert = false

    private var emailText: String {
        user?.email ?? "No email on file"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("LightGreen"), Color("SoftCream")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // ===============================
                    // MARK: Avatar + Email
                    // ===============================
                    VStack(spacing: 14) {
                        Button {
                            checkPhotoPermissionAndOpen()
                        } label: {
                            ZStack {
                                if let data = profileImageData,
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color("DarkGreen"))
                                        .padding(16)
                                }
                            }
                            .frame(width: 120, height: 120)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(color: Color("DarkGreen").opacity(0.25), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 50)

                        Text(emailText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // ===============================
                    // MARK: Display Name Editor
                    // ===============================
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Display Name")
                            .font(.headline)
                            .foregroundColor(Color("DarkGreen"))

                        TextField("Your name", text: $editableName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.95))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color("DarkGreen").opacity(0.2), lineWidth: 1)
                                    )
                            )

                        if let nameSaveError {
                            Text(nameSaveError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Button {
                            saveDisplayName()
                        } label: {
                            if isSavingName {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            } else {
                                Text("Save Display Name")
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                        }
                        .background(Color("DarkGreen"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 28)

                    // ===============================
                    // MARK: Log Out Button
                    // ===============================
                    Button {
                        auth.signOut()
                    } label: {
                        Text("Log Out")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .foregroundColor(Color("DarkGreen"))
                            .cornerRadius(14)
                            .shadow(color: Color("DarkGreen").opacity(0.2), radius: 6, y: 3)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 32)
                }
            }
        }

        // ===============================
        // MARK: Photo Picker + Alerts
        // ===============================
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images,
            preferredItemEncoding: .compatible
        )
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = await loadImageData(from: newItem) {
                    profileImageData = data
                }
            }
        }

        .alert("Photo Access Needed", isPresented: $showPhotoDeniedAlert) {
            Button("Open Settings") {
                PhotoPermissionManager.openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Allow photo access to change your profile picture.")
        }
        .onAppear {
            let fallback = user?.email ?? "Garden Lover"
            editableName = (user?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap {
                $0.isEmpty ? nil : $0
            } ?? fallback
        }
    }

    private func checkPhotoPermissionAndOpen() {
        switch PhotoPermissionManager.status() {
        case .authorized, .limited:
            showPhotoPicker = true
        case .notDetermined:
            PhotoPermissionManager.requestReadWrite { granted in
                if granted { showPhotoPicker = true } else { showPhotoDeniedAlert = true }
            }
        case .denied, .restricted:
            showPhotoDeniedAlert = true
        @unknown default:
            break
        }
    }

    private func saveDisplayName() {
        guard let user = Auth.auth().currentUser else { return }

        let trimmed = editableName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            nameSaveError = "Display name cannot be empty."
            return
        }

        isSavingName = true
        nameSaveError = nil

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = trimmed
        changeRequest.commitChanges { error in
            DispatchQueue.main.async {
                self.isSavingName = false
                if let error = error {
                    self.nameSaveError = error.localizedDescription
                    print("Failed to update displayName:", error)
                } else {
                    self.nameSaveError = nil
                }
            }
        }
    }
}

// ===============================================================
// MARK: - PLANTBOOK VIEW
// ===============================================================
struct PlantbookView: View {
    let entries: [PlantbookEntry]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("LightGreen"), Color("SoftCream")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 6) {
                        Text("Plantbook")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color("DarkGreen"))

                        Text(entries.isEmpty
                             ? "Add plants to unlock species in your Plantbook."
                             : "Your discovered plant species.")
                            .font(.subheadline)
                            .foregroundColor(Color("DarkGreen").opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.top, 24)

                    // Picture-book cards
                    VStack(spacing: 22) {
                        ForEach(entries) { entry in
                            PlantbookCard(entry: entry)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

private struct PlantbookCard: View {
    let entry: PlantbookEntry

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Group {
                    if let uiImage = loadedImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else if isLoading {
                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color("LightGreen").opacity(0.6),
                                            Color("SoftCream").opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            ProgressView()
                        }
                    } else {
                        // fallback placeholder if we have nothing at all
                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color("LightGreen").opacity(0.7),
                                            Color("SoftCream").opacity(0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            VStack(spacing: 8) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(Color("DarkGreen").opacity(0.9))

                                Text("Image coming soon")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color("DarkGreen").opacity(0.15), lineWidth: 1.5)
                )
                .clipped()

                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(radius: 4)
                        Spacer()
                    }
                    .padding(14)
                }
            }

            Text(entry.speciesName)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("DarkGreen"))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(color: Color("DarkGreen").opacity(0.18), radius: 10, y: 5)
        )
        .onAppear {
            loadImageIfNeeded()
        }
    }

    private func loadImageIfNeeded() {
        guard !isLoading, loadedImage == nil else { return }
        isLoading = true

        // Immediately show the user's photo if we have one
        if let data = entry.fallbackImageData,
           let uiImage = UIImage(data: data) {
            self.loadedImage = uiImage
        }

        // Ask backend for a nicer species image; override only if it returns one
        PlantImageService.fetchSpeciesImage(speciesName: entry.speciesName) { image in
            DispatchQueue.main.async {
                if let image = image {
                    self.loadedImage = image   // backend wins if available
                }
                self.isLoading = false
            }
        }
    }
}

// ===============================================================
// MARK: - PLANT CARD
// ===============================================================
struct PlantCard: View {
    @Binding var plant: Plant

    // ✅ ADDED: Callback to trigger save when data changes
    var onSave: (Plant) -> Void

    var onDelete: (UUID) -> Void = { _ in }

    @State private var showReminders = false
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow
            remindersToggleRow

            if showReminders {
                remindersSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color("DarkGreen").opacity(0.20), lineWidth: 1.4)
                )
        )
        .padding(.horizontal, 8)
        .sheet(isPresented: $isEditing) {
            EditPlantSheet(
                isPresented: $isEditing,
                plant: $plant,
                onDelete: { onDelete(plant.id) }
            )
            // ✅ ADDED: Save when the edit sheet closes
            .onDisappear {
                onSave(plant)
            }
        }
        // ✅ ADDED: Save immediately if tasks (toggles/frequency) change
        .onChange(of: plant.tasks) { _ in
            onSave(plant)
        }
    }

    // ===============================================================
    // MARK: - REMINDER ROW
    // ===============================================================
    private struct ReminderRow: View {
        @Binding var task: PlantTask
        let plant: Plant
        @State private var showNotifDeniedAlert = false

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
            .alert("Notifications are Off", isPresented: $showNotifDeniedAlert) {
                Button("Open Settings") { NotificationManager.openSettings() }
                Button("OK", role: .cancel) { }
            } message: {
                Text("To receive plant reminders, enable notifications in Settings.")
            }
        }

        private var subLabel: some View {
            let title = task.title.lowercased()
            let text: String

            if title == "water" {
                if task.waterMode == .timesPerDay {
                    text = "Repeats \(task.timesPerDay)x per day"
                } else {
                    text = "Every \(task.frequencyDays) day\(task.frequencyDays == 1 ? "" : "s")"
                }
            } else {
                text = "Every \(task.frequencyDays) day\(task.frequencyDays == 1 ? "" : "s")"
            }

            return Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 16)
                .eraseToAnyView()
        }

        private func handleToggle(isOn: Bool) {
            let id = "\(plant.id.uuidString)::\(task.title.lowercased())"

            if isOn {
                NotificationManager.currentStatus { status in
                    switch status {
                    case .notDetermined:
                        NotificationManager.requestAuthorization { granted in
                            if granted {
                                scheduleCurrentReminder(identifier: id)
                            } else {
                                task.reminderEnabled = false
                                showNotifDeniedAlert = true
                            }
                        }
                    case .denied:
                        task.reminderEnabled = false
                        showNotifDeniedAlert = true
                    case .authorized, .provisional, .ephemeral:
                        scheduleCurrentReminder(identifier: id)
                    @unknown default:
                        task.reminderEnabled = false
                    }
                }
            } else {
                NotificationManager.cancel(identifier: id)
            }
        }

        private func scheduleCurrentReminder(identifier: String) {
            let title = task.title.lowercased()
            let seconds: TimeInterval

            if title == "water" {
                if task.waterMode == .timesPerDay {
                    let timesPerDay = max(task.timesPerDay, 1)
                    seconds = TimeInterval((24 * 60 * 60) / timesPerDay)
                } else {
                    let days = max(task.frequencyDays, 1)
                    seconds = TimeInterval(days * 24 * 60 * 60)
                }
            } else {
                let days = max(task.frequencyDays, 1)
                seconds = TimeInterval(days * 24 * 60 * 60)
            }

            NotificationManager.scheduleRepeating(
                taskTitle: task.title,
                plantName: plant.name.isEmpty ? "your plant" : plant.name,
                identifier: identifier,
                intervalSeconds: seconds
            )
        }
    }

    // ===============================================================
    // MARK: - HEADER ROW
    // ===============================================================

    private var headerRow: some View {
        HStack(spacing: 14) {
            HStack(spacing: 8) {
                Text(plant.name.isEmpty ? "Plant Name" : plant.name)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(Color("DarkGreen"))

                Button {
                    isEditing = true
                } label: {
                    Text("Edit")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color("DarkGreen").opacity(0.08))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color("DarkGreen").opacity(0.18), lineWidth: 1)
                        )
                        .foregroundColor(Color("DarkGreen"))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }

            if let data = plant.imageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color("DarkGreen").opacity(0.25), lineWidth: 1)
                    )
            }
        }
    }

    // ===============================================================
    // MARK: - REMINDER TOGGLE ROW
    // ===============================================================

    private var remindersToggleRow: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                showReminders.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: showReminders ? "chevron.up" : "chevron.down")
                Text("Reminders")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .foregroundColor(Color("DarkGreen").opacity(0.7))
        }
        .buttonStyle(.plain)
    }

    // ===============================================================
    // MARK: - REMINDER SECTION
    // ===============================================================

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Reminders", systemImage: "bell")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color("DarkGreen"))

                Spacer()

                Text("Enable Notifications")
                    .font(.headline)
                    .foregroundColor(Color("DarkGreen"))
            }

            Divider()
                .background(Color("DarkGreen").opacity(0.15))

            ForEach($plant.tasks) { $task in
                ReminderRow(task: $task, plant: plant)
                    .padding(.vertical, 4)
            }

            if !plant.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Divider()
                    .background(Color("DarkGreen").opacity(0.12))
                    .padding(.top, 4)

                Text("Notes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color("DarkGreen").opacity(0.8))
                    .padding(.top, 4)

                Text(plant.notes)
                    .font(.subheadline)
                    .foregroundColor(Color("DarkGreen").opacity(0.7))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color("LightGreen").opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color("DarkGreen").opacity(0.18), lineWidth: 1)
                )
        )
    }
}

// ===============================================================
// MARK: - ADD PLANT
// ===============================================================
struct AddPlantSheet: View {
    @State private var tasks: [PlantTask] = [
        PlantTask(title: "water",
                  reminderEnabled: false,
                  frequencyDays: 0,
                  timesPerDay: 0,
                  waterMode: .timesPerDay),
        PlantTask(title: "fertilize",
                  reminderEnabled: false,
                  frequencyDays: 0,
                  timesPerDay: 0,
                  waterMode: .everyXDays),
        PlantTask(title: "trimming",
                  reminderEnabled: false,
                  frequencyDays: 0,
                  timesPerDay: 0,
                  waterMode: .everyXDays)
    ]

    @Binding var isPresented: Bool
    var onSave: (Plant) -> Void

    // Form state
    @State private var name = ""
    @State private var species = ""
    @State private var notes = ""

    // Photo state
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showPhotoPicker = false
    @State private var showPhotoDeniedAlert = false

    // Notification permission
    @State private var showNotifDeniedAlert = false

    private var canSave: Bool {
            !name.trimmingCharacters(in: .whitespaces).isEmpty &&
            !species.trimmingCharacters(in: .whitespaces).isEmpty
        }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("LightGreen"), Color("SoftCream")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Form {
                    // PHOTO
                    Section("Photo") {
                        HStack(spacing: 16) {
                            Group {
                                if let imageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
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

                            Button {
                                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                                switch status {
                                case .notDetermined:
                                    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                                        DispatchQueue.main.async {
                                            if status == .authorized || status == .limited {
                                                showPhotoPicker = true
                                            } else {
                                                showPhotoDeniedAlert = true
                                            }
                                        }
                                    }
                                case .authorized, .limited:
                                    showPhotoPicker = true
                                case .denied, .restricted:
                                    showPhotoDeniedAlert = true
                                @unknown default:
                                    break
                                }
                            } label: {
                                Label("Choose Photo", systemImage: "photo")
                                    .foregroundColor(Color("DarkGreen"))
                            }
                        }
                    }

                    // BASIC
                    Section("Basics") {
                        TextField("Plant name (required)", text: $name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                        TextField("Plant species (required)", text: $species)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }

                    // REMINDERS
                    Section("Reminders") {
                        ForEach($tasks) { $task in
                            VStack(alignment: .leading, spacing: 8) {

                                // Main row: title + toggle
                                HStack {
                                    Text(task.title.capitalized)
                                        .font(.system(size: 18, weight: .semibold))
                                    Spacer()
                                    Toggle(
                                        "",
                                        isOn: Binding(
                                            get: { task.reminderEnabled },
                                            set: { isOn in
                                                if isOn {
                                                    // Ask for notification permission if needed
                                                    NotificationManager.currentStatus { status in
                                                        switch status {
                                                        case .notDetermined:
                                                            NotificationManager.requestAuthorization { granted in
                                                                if granted {
                                                                    task.reminderEnabled = true
                                                                } else {
                                                                    task.reminderEnabled = false
                                                                    showNotifDeniedAlert = true
                                                                }
                                                            }
                                                        case .denied:
                                                            task.reminderEnabled = false
                                                            showNotifDeniedAlert = true
                                                        case .authorized, .provisional, .ephemeral:
                                                            task.reminderEnabled = true
                                                        @unknown default:
                                                            task.reminderEnabled = false
                                                        }
                                                    }
                                                } else {
                                                    // Turning OFF – just update the model
                                                    task.reminderEnabled = false
                                                }
                                            }
                                        )
                                    )
                                    .labelsHidden()
                                }

                                // WATER SPECIAL CASE
                                if task.title.lowercased() == "water" {

                                    // Per Day vs Every X Days
                                    Picker("Water Schedule Mode", selection: $task.waterMode) {
                                        ForEach(WaterScheduleMode.allCases) { mode in
                                            Text(mode.label).tag(mode)
                                        }
                                    }
                                    .pickerStyle(.segmented)

                                    if task.waterMode == .timesPerDay {
                                        // "X times per day"
                                        Text("\(task.timesPerDay) time\(task.timesPerDay == 1 ? "" : "s") per day")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        HStack {
                                            Spacer()
                                            Stepper(
                                                "",
                                                value: $task.timesPerDay,
                                                in: 0...10
                                            )
                                            .labelsHidden()
                                            .frame(width: 120)
                                        }

                                    } else {
                                        // "Every X days"
                                        Text("Every \(task.frequencyDays) day\(task.frequencyDays == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        HStack {
                                            Spacer()
                                            Stepper(
                                                "",
                                                value: $task.frequencyDays,
                                                in: 0...60
                                            )
                                            .labelsHidden()
                                            .frame(width: 120)
                                        }
                                    }

                                } else {
                                    // FERTILIZE + TRIMMING
                                    Text("Every \(task.frequencyDays) day\(task.frequencyDays == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    HStack {
                                        Spacer()
                                        Stepper(
                                            "",
                                            value: $task.frequencyDays,
                                            in: 0...180
                                        )
                                        .labelsHidden()
                                        .frame(width: 120)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .alert("Notifications are Off", isPresented: $showNotifDeniedAlert) {
                        Button("Open Settings") {
                            NotificationManager.openSettings()
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Enable notifications in Settings → GrowMyGarden.")
                    }

                    Section("Notes") {
                        TextEditor(text: $notes)

                            .frame(minHeight: 80, maxHeight: 140)   // smaller but scrollable
                            .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.quaternary, lineWidth: 1)
                            )
                            .listRowInsets(EdgeInsets())
                    }
                }
                .scrollContentBackground(.hidden)
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
                        let plant = Plant(
                            name: name.trimmingCharacters(in: .whitespaces),
                            species: species.trimmingCharacters(in: .whitespaces),
                            imageData: imageData,
                            notes: notes,
                            tasks: tasks
                        )
                        onSave(plant)
                        isPresented = false
                    }
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.large])           // always open full-height
        .presentationDragIndicator(.visible)
        // Show Photos picker only after permission is granted
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images,
            preferredItemEncoding: .compatible
        )
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = await loadImageData(from: newItem) {
                    imageData = data
                }
            }
        }
        .alert("Photos Access Needed", isPresented: $showPhotoDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Allow photo access to pick a plant image.")
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
    @State private var newSpecies: String = ""
    @State private var newNotes: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var newImageData: Data?

    @State private var showPhotoPicker = false
    @State private var showPhotoDeniedAlert = false

    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            // background
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
                        if !newSpecies.trimmingCharacters(in: .whitespaces).isEmpty {
                                plant.species = newSpecies.trimmingCharacters(in: .whitespaces)
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

                        // Photo picker section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Photo")
                                .font(.headline)
                                .foregroundColor(Color("DarkGreen"))

                            HStack(spacing: 16) {
                                Group {
                                    if let newImageData, let uiImage = UIImage(data: newImageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                    } else if let data = plant.imageData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
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

                                Button {
                                    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                                    switch status {
                                    case .notDetermined:
                                        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                                            DispatchQueue.main.async {
                                                if status == .authorized || status == .limited {
                                                    showPhotoPicker = true
                                                } else {
                                                    showPhotoDeniedAlert = true
                                                }
                                            }
                                        }
                                    case .authorized, .limited:
                                        showPhotoPicker = true
                                    case .denied, .restricted:
                                        showPhotoDeniedAlert = true
                                    @unknown default:
                                        break
                                    }
                                } label: {
                                    Label("Choose Photo", systemImage: "photo")
                                        .foregroundColor(Color("DarkGreen"))
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                        }

                        // Name
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
                        // species
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plant Species")
                                .font(.headline)
                                .foregroundColor(Color("DarkGreen"))

                            TextField("Enter species", text: $newSpecies)
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
                        // Reminders
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reminders")
                                .font(.headline)
                                .foregroundColor(Color("DarkGreen"))

                            ForEach($plant.tasks) { $task in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Toggle(isOn: $task.reminderEnabled) {
                                            Text(task.title.capitalized)
                                                .font(.subheadline.weight(.semibold))
                                        }
                                    }

                                    if task.title.lowercased() == "water" {
                                        Picker("Water Schedule Mode", selection: $task.waterMode) {
                                            ForEach(WaterScheduleMode.allCases) { mode in
                                                Text(mode.label).tag(mode)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .onChange(of: task.waterMode) { _ in
                                            rescheduleIfNeeded(task: task)
                                        }

                                        if task.waterMode == .timesPerDay {
                                            HStack {
                                                Text("Times per day")
                                                Spacer()
                                                Stepper(
                                                    "\(task.timesPerDay)x",
                                                    value: $task.timesPerDay,
                                                    in: 1...10
                                                )
                                            }
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 4)
                                            .onChange(of: task.timesPerDay) { _ in
                                                rescheduleIfNeeded(task: task)
                                            }

                                        } else {
                                            HStack {
                                                Text("Every")
                                                Spacer()
                                                Stepper(
                                                    "\(task.frequencyDays) day\(task.frequencyDays == 1 ? "" : "s")",
                                                    value: $task.frequencyDays,
                                                    in: 1...60
                                                )
                                            }
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 4)
                                            .onChange(of: task.frequencyDays) { _ in
                                                rescheduleIfNeeded(task: task)
                                            }
                                        }

                                    } else {
                                        HStack {
                                            Text("Every")
                                            Spacer()
                                            Stepper(
                                                "\(task.frequencyDays) day\(task.frequencyDays == 1 ? "" : "s")",
                                                value: $task.frequencyDays,
                                                in: 1...180
                                            )
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 4)
                                        .onChange(of: task.frequencyDays) { _ in
                                            rescheduleIfNeeded(task: task)
                                        }
                                    }

                                }
                                .padding(.vertical, 4)
                            }
                        }
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(Color("DarkGreen"))

                            TextEditor(text: $newNotes)
                                .frame(minHeight: 80, maxHeight: 140)
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

                // trash popup
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
        // show photos only after permission
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images,
            preferredItemEncoding: .compatible
        )
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = await loadImageData(from: newItem) {
                    newImageData = data
                }
            }
        }
        .alert("Photos Access Needed", isPresented: $showPhotoDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Allow photo access to pick or update a plant image.")
        }
        .onAppear {
            newName = plant.name
            newSpecies = plant.species
            newNotes = plant.notes
        }
    }
    private func rescheduleIfNeeded(task: PlantTask) {
        guard task.reminderEnabled else { return }

        let identifier = "\(plant.id.uuidString)::\(task.title.lowercased())"
        let seconds: TimeInterval

        if task.title.lowercased() == "water" {
            if task.waterMode == .timesPerDay {
                let timesPerDay = max(task.timesPerDay, 1)
                seconds = TimeInterval((24 * 60 * 60) / timesPerDay)
            } else {
                let days = max(task.frequencyDays, 1)
                seconds = TimeInterval(days * 24 * 60 * 60)
            }
        } else {
            let days = max(task.frequencyDays, 1)
            seconds = TimeInterval(days * 24 * 60 * 60)
        }

        NotificationManager.scheduleRepeating(
            taskTitle: task.title,
            plantName: plant.name.isEmpty ? "your plant" : plant.name,
            identifier: identifier,
            intervalSeconds: seconds
        )
    }

}

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
