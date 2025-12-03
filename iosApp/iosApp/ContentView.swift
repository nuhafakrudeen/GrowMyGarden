import UserNotifications
import Photos
import PhotosUI
import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit
import AuthenticationServices
import CryptoKit
import Shared
import KMPNativeCoroutinesCombine
import Combine


// ===============================================================
// MARK: - Backend (Kotlin) Plant Adapter
// ===============================================================

/// Wraps the Kotlin DashboardViewModel so SwiftUI can observe it.
final class BackendPlantAdapter: ObservableObject {
    @Published var backendPlants: [Shared.Plant] = []

    private let vm: DashboardViewModel
    private var cancellables = Set<AnyCancellable>()

    init() {
        print("👉 BackendPlantAdapter init - getting DashboardViewModel")
        vm = HelperKt.getDashboardViewModel()
        print("✅ Got DashboardViewModel from Kotlin:", vm)

        // Observe Kotlin StateFlow<List<Plant>> via plantsStateFlow
        let publisher: AnyPublisher<[Shared.Plant], Error> =
            createPublisher(for: vm.plantsStateFlow)

        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("❌ Error observing plantsStateFlow:", error)
                    }
                },
                receiveValue: { [weak self] (plants: [Shared.Plant]) in
                    print("🌱 Received \(plants.count) plants from Kotlin")
                    self?.backendPlants = plants
                }
            )
            .store(in: &cancellables)
    }

    /// Persist a SwiftUI Plant to the backend.
    func save(uiPlant: Plant) {
        let backend = HelperKt.createBackendPlant(
            name: uiPlant.name,
            species: uiPlant.species
        )
        vm.savePlant(plant: backend)
    }

    /// Delete the corresponding backend plant for a given SwiftUI Plant.
    func delete(uiPlant: Plant) {
        if let backend = backendPlants.first(where: {
            $0.name == uiPlant.name && $0.species == uiPlant.species
        }) {
            vm.deletePlant(plant: backend)
        }
    }
}

/// Convert a backend Shared.Plant into your local SwiftUI Plant model.
func convertBackendPlant(_ backend: Shared.Plant) -> Plant {
    // FIX: Provide default tasks so the UI section appears.
    // Since the backend doesn't store tasks yet, we create defaults.
    // The merging logic in PlantsHomeView will preserve user edits.
    let defaultTasks = [
        PlantTask(title: "water", reminderEnabled: false, frequencyDays: 0, timesPerDay: 0, waterMode: .timesPerDay),
        PlantTask(title: "fertilize", reminderEnabled: false, frequencyDays: 0, timesPerDay: 0, waterMode: .everyXDays),
        PlantTask(title: "trimming", reminderEnabled: false, frequencyDays: 0, timesPerDay: 0, waterMode: .everyXDays)
    ]
    
    return Plant(
        name: backend.name,
        species: backend.species,
        imageData: nil,
        notes: "",
        tasks: defaultTasks // 👈 Now returns tasks instead of []
    )
}

//shared auth state for the app
final class AuthManager: NSObject, ObservableObject {
    @Published var isLoggedIn: Bool = false

    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    fileprivate var currentNonce: String?
    
    override init() {
        super.init()

        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isLoggedIn = (user != nil)
            }
        }
    }
    
    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
        isLoggedIn = false
    }
    
}

extension AuthManager {
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("No Firebase clientID")
            return
        }

        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = scene.windows.first?.rootViewController
        else {
            print("No root view controller for Google Sign-In")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error = error {
                print("Google Sign-In error:", error)
                return
            }

            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                print("Google Sign-In: missing user or idToken")
                return
            }

            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    print("Firebase Google auth failed:", error)
                } else {
                    print("Google Sign-In + Firebase auth success")
                    
                }
            }
        }
    }
}

extension AuthManager {
    func signInWithApple() {
        print("Starting Apple sign-in")

        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
        
        
    }

    // MARK: - Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with status \(status)")
            }

            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}


extension AuthManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        print("Apple authorization completed")

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("No AppleIDCredential")
            return
        }

        guard let nonce = currentNonce else {
            print("Missing currentNonce")
            return
        }

        guard let appleIDTokenData = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDTokenData, encoding: .utf8) else {
            print("Unable to get identity token")
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        print("Got Apple credential, signing in with Firebase...")

        Auth.auth().signIn(with: credential) { _, error in
            if let error = error {
                print("Firebase Apple auth error:", error)
            } else {
                print("Firebase Apple auth success")
                // listener will update isLoggedIn
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        print("Sign in with Apple failed:", error)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}


// ===============================================================
// MARK: - AUTH ROOT (Chooses between login and main app)
// ===============================================================
struct AuthRootView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        if auth.isLoggedIn {
            PlantsHomeView()
                .onAppear {
                    print("🌱 AuthRootView: showing PlantsHomeView, isLoggedIn = \(auth.isLoggedIn)")
                }
        } else {
            AuthView {
                print("✅ onAuthSuccess callback fired")
            }
            .onAppear {
                print("🌱 AuthRootView: showing AuthView, isLoggedIn = \(auth.isLoggedIn)")
            }
        }
    }
}


enum NotificationManager {
    static func currentStatus(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            completion(s.authorizationStatus)
        }
    }
    static func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }
    static func scheduleRepeating(taskTitle: String,
                                  plantName: String,
                                  identifier: String,
                                  intervalSeconds: TimeInterval) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Time to \(taskTitle.capitalized)"
        content.body  = "Don’t forget to \(taskTitle) your \(plantName) 🌿"
        content.sound = .default

        let seconds = max(60, intervalSeconds)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: true)

        UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
    static func cancel(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }
}

enum PhotoPermissionManager {
    static func status() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    static func requestReadWrite(_ completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { s in
            DispatchQueue.main.async { completion(s == .authorized || s == .limited) }
        }
    }
    static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }
}

// ===============================================================
// MARK: - PLANT IMAGE SERVICE (Backend placeholder)
// ===============================================================

enum PlantImageService {
    // Fetches a UIImage for a given species name from backend.
    static func fetchSpeciesImage(speciesName: String,
                                  completion: @escaping (UIImage?) -> Void) {
        // TODO: Replace with real backend call.
        // Placeholder: currently returns nil so the UI shows the fallback.
        completion(nil)
    }
}

// ===============================================================
// MARK: - SEARCH SERVICE (Backend placeholder)
// ===============================================================

struct SearchResult: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let detail: String
}

enum SearchService {
    static func search(query: String, completion: @escaping ([SearchResult]) -> Void) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion([])
            return
        }

        // 1. Build URL to your API
        //    e.g. GET https://api.yourapp.com/plants/search?q=<query>
        guard var components = URLComponents(string: "https://api.yourapp.com/plants/search") else {
            completion([])
            return
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmed)
        ]

        guard let url = components.url else {
            completion([])
            return
        }

        // 2. Call backend
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Basic error handling
            guard
                let data = data,
                error == nil
            else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            // 3. Decode whatever your backend returns
            struct PlantSearchDTO: Decodable {
                let name: String
                let summary: String
                let details: String
            }

            do {
                let decoded = try JSONDecoder().decode([PlantSearchDTO].self, from: data)

                let mapped = decoded.map { dto in
                    SearchResult(
                        title: dto.name,
                        subtitle: dto.summary,
                        detail: dto.details
                    )
                }

                DispatchQueue.main.async {
                    completion(mapped)
                }
            } catch {
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }
}



// Helper to normalize PhotosPicker images into JPEG Data
private func loadImageData(from item: PhotosPickerItem?) async -> Data? {
    guard let item = item else { return nil }

    // Try to load the raw Data (Transferable)
    if let rawData = try? await item.loadTransferable(type: Data.self),
       let uiImage = UIImage(data: rawData),
       let jpegData = uiImage.jpegData(compressionQuality: 0.9) {
        return jpegData
    }

    return nil
}

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

//Represents a plant with its details and reminders.
struct Plant: Identifiable, Hashable {
    let id = UUID()
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
                        // EMPTY STATE
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
                                ForEach($store.plants) { $plant in
                                    PlantCard(
                                        plant: $plant,
                                        onDelete: { id in
                                            if let uiPlant = store.plants.first(where: { $0.id == id }) {
                                                backendAdapter.delete(uiPlant: uiPlant)
                                            }
                                            store.plants.removeAll { $0.id == id }
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
                // 2) Persist to Kotlin backend
                backendAdapter.save(uiPlant: newPlant)
            }
        }
        .onReceive(backendAdapter.$backendPlants) { backendPlants in
            // FIX: Merge logic to preserve local data (Tasks, Notes, Photos)
            // If we just overwrite with backend data, we lose the task settings
            // because the backend doesn't store tasks/photos yet.
            
            var existingMap = [String: Plant]()
            // Map existing plants by "Name|Species" key
            for p in store.plants {
                let key = p.name + "|" + p.species
                existingMap[key] = p
            }

            let merged = backendPlants.map { bp -> Plant in
                let key = bp.name + "|" + bp.species
                if let existing = existingMap[key] {
                    // Keep the existing local plant (preserves tasks/notes/image)
                    return existing
                } else {
                    // New plant from backend? Convert it (now with default tasks)
                    return convertBackendPlant(bp)
                }
            }
            
            // Only update if the count changed or we have new data
            // (Simple check to avoid infinite loops if objects are equatable)
            if merged.count != store.plants.count || !merged.isEmpty {
               store.plants = merged
            }
        }
    }
}

// ... rest of the file (SearchView, ProfileView, PlantCard etc) remains exactly the same ...
// (I have included the full file above, but the critical changes are in convertBackendPlant and PlantsHomeView.onReceive)

// ===============================================================
// MARK: - SEARCH VIEW
// ===============================================================
struct SearchView: View {
    @State private var query: String = ""
    @State private var results: [SearchResult] = []
    @State private var isLoading: Bool = false
    @State private var hasSearched: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("LightGreen"), Color("SoftCream")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color("DarkGreen").opacity(0.7))

                    TextField("Search plants, care tips, species...", text: $query)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            performSearch()
                        }

                    if !query.isEmpty {
                        Button {
                            query = ""
                            results = []
                            hasSearched = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.95))
                        .shadow(color: Color("DarkGreen").opacity(0.15), radius: 6, y: 3)
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Content
                if isLoading {
                    Spacer()
                    ProgressView("Searching…")
                        .foregroundColor(Color("DarkGreen"))
                    Spacer()
                } else if results.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: hasSearched ? "leaf.circle" : "text.magnifyingglass")
                            .font(.system(size: 40, weight: .regular))
                            .foregroundColor(Color("DarkGreen").opacity(0.8))

                        Text(hasSearched ? "No results found." : "Start by typing something to search.")
                            .font(.subheadline)
                            .foregroundColor(Color("DarkGreen").opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(results) { result in
                                SearchResultCard(result: result)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
    }

    private func performSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        hasSearched = true
        SearchService.search(query: trimmed) { newResults in
            DispatchQueue.main.async {
                self.results = newResults
                self.isLoading = false
            }
        }
    }
}

// A simple “info flows nicely” card for each search result
private struct SearchResultCard: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color("DarkGreen"))

            if !result.subtitle.isEmpty {
                Text(result.subtitle)
                    .font(.footnote)
                    .foregroundColor(Color("DarkGreen").opacity(0.75))
            }

            if !result.detail.isEmpty {
                Text(result.detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(color: Color("DarkGreen").opacity(0.16), radius: 8, y: 4)
        )
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
                if granted { showPhotoPicker = true }
                else { showPhotoDeniedAlert = true }
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
           let ui = UIImage(data: data) {
            self.loadedImage = ui
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
               let ui = UIImage(data: data) {
                Image(uiImage: ui)
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

private struct ReminderConfigRow: View {
    @Binding var task: PlantTask

    var isWater: Bool {
        task.title.lowercased() == "water"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // main toggle
            HStack {
                Toggle(isOn: $task.reminderEnabled) {
                    Text(task.title.capitalized)
                        .font(.subheadline.weight(.semibold))
                }
            }

            if isWater {
                // mode picker: per day vs every X days
                Picker("Water Schedule Mode", selection: $task.waterMode) {
                    ForEach(WaterScheduleMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if task.waterMode == .timesPerDay {
                    // 0 ... N times per day
                    let label = "\(task.timesPerDay) time\(task.timesPerDay == 1 ? "" : "s") per day"

                    Stepper(
                        label,
                        value: $task.timesPerDay,
                        in: 0...10
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                } else {
                    // every X days (0 allowed)
                    let label = "Every \(task.frequencyDays) day\(task.frequencyDays == 1 ? "" : "s")"

                    Stepper(
                        label,
                        value: $task.frequencyDays,
                        in: 0...60
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            } else {
                // fertilize / trimming: every X days, starting at 0
                let label = "Every \(task.frequencyDays) day\(task.frequencyDays == 1 ? "" : "s")"

                Stepper(
                    label,
                    value: $task.frequencyDays,
                    in: 0...180
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

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
                let n = max(task.timesPerDay, 1)
                seconds = TimeInterval((24 * 60 * 60) / n)
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

private extension View { func eraseToAnyView() -> AnyView { AnyView(self) } }

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

                            Button {
                                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                                switch status {
                                case .notDetermined:
                                    PHPhotoLibrary.requestAuthorization(for: .readWrite) { s in
                                        DispatchQueue.main.async {
                                            if s == .authorized || s == .limited {
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
                                    Toggle("", isOn: $task.reminderEnabled)
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
            //background
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

                                Button {
                                    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                                    switch status {
                                    case .notDetermined:
                                        PHPhotoLibrary.requestAuthorization(for: .readWrite) { s in
                                            DispatchQueue.main.async {
                                                if s == .authorized || s == .limited {
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
                        //species
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
                let n = max(task.timesPerDay, 1)
                seconds = TimeInterval((24 * 60 * 60) / n)
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


//MARK: - BOTTOM PAGES
enum AppTab: Hashable{
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

// ===============================================================
// MARK: - AUTH VIEW (Sign In / Create Account)
// ===============================================================

struct AuthView: View {
    enum Mode { case signIn, signUp }

    @State private var mode: Mode = .signIn
    let onAuthSuccess: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color("LightGreen"), Color("SoftCream")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // App title
                VStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color("DarkGreen"))

                    Text("Grow My Garden")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color("DarkGreen"))

                    Text(mode == .signIn ? "Welcome back! Log in to continue" :
                                            "Create an account to get started")
                        .font(.subheadline)
                        .foregroundColor(Color("DarkGreen").opacity(0.8))
                }
                .padding(.top, 40)

                // SIGN IN / CREATE ACCOUNT toggle
                HStack(spacing: 0) {
                    authToggleButton(title: "Sign In", isActive: mode == .signIn) {
                        mode = .signIn
                    }
                    authToggleButton(title: "Create Account", isActive: mode == .signUp) {
                        mode = .signUp
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color("DarkGreen").opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 32)

                VStack {
                    if mode == .signIn {
                        SignInForm(onLoginSuccess: onAuthSuccess)
                    } else {
                        SignUpForm(onSignUpSuccess: onAuthSuccess) {
                            mode = .signIn
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.96))
                        .shadow(color: Color("DarkGreen").opacity(0.18), radius: 14, y: 6)
                )
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    private func authToggleButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if isActive {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color("DarkGreen"))
                        .padding(4)
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isActive ? .white : Color("DarkGreen"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
        .buttonStyle(.plain)
    }
}


// ===============================================================
// MARK: - SIGN IN FORM
// ===============================================================

struct SignInForm: View {
    @EnvironmentObject var auth: AuthManager
    
    @State private var username: String = ""   // email
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showForgotSheet: Bool = false
    @State private var forgotEmail: String = ""

    let onLoginSuccess: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Login")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("DarkGreen"))

            // Email (was Username)
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("you@example.com", text: $username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
            }

            // Password
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.caption)
                    .foregroundColor(.secondary)
                SecureField("Enter your password", text: $password)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
            }

            // Forgot password
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    forgotEmail = username
                    showForgotSheet = true
                }
                .font(.caption)
                .foregroundColor(Color("DarkGreen"))
            }

            // Login button
            Button {
                signIn()
            } label: {
                Text("LOGIN")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("DarkGreen"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 4)

            if showError {
                Text(errorMessage.isEmpty ? "Please enter email and password." : errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Divider (OR)
            HStack {
                Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.3))
                Text("OR")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.3))
            }
            .padding(.vertical, 4)

            // Continue with Apple / Google
            Button {
                auth.signInWithApple()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                    Text("Login with Apple")
                }
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("DarkGreen").opacity(0.3), lineWidth: 1)
                )
            }

            Button {
                auth.signInWithGoogle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                    Text("Login with Google")
                }
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("DarkGreen").opacity(0.3), lineWidth: 1)
                )
            }

        }
        .sheet(isPresented: $showForgotSheet) {
            ForgotPasswordSheet(email: $forgotEmail)
        }
    }

    private func signIn() {
        let email = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let pwd = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !email.isEmpty, !pwd.isEmpty else {
            showError = true
            errorMessage = "Please enter email and password."
            return
        }

        Auth.auth().signIn(withEmail: email, password: pwd) { _, error in
            if let error = error {
                showError = true
                errorMessage = error.localizedDescription
                print("Sign in failed:", error)
            } else {
                showError = false
                errorMessage = ""
                onLoginSuccess()
            }
        }
    }
}




// ===============================================================
// MARK: - SIGN UP FORM
// ===============================================================

struct SignUpForm: View {
    @EnvironmentObject var auth: AuthManager
    
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    let onSignUpSuccess: () -> Void
    let onSwitchToLogin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create an Account")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("DarkGreen"))

            // Username
            VStack(alignment: .leading, spacing: 6) {
                Text("Username")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Choose a username", text: $username)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
            }

            // Email
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("you@example.com", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
            }

            // Password
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.caption)
                    .foregroundColor(.secondary)
                SecureField("Create a password", text: $password)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
            }

            // Create account button
            Button {
                signUp()
            } label: {
                Text("CREATE ACCOUNT")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("DarkGreen"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 4)

            if showError {
                Text(errorMessage.isEmpty ? "Please fill in all fields." : errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Already have account? Login
            HStack {
                Text("Already have an account?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("Login") {
                    onSwitchToLogin()
                }
                .font(.caption)
                .foregroundColor(Color("DarkGreen"))
            }

            // Divider
            HStack {
                Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.3))
                Text("OR")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.3))
            }
            .padding(.vertical, 4)

            // Continue with
            Button {
                auth.signInWithApple()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                    Text("Sign up with Apple")
                }
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("DarkGreen").opacity(0.3), lineWidth: 1)
                )
            }

            Button {
                auth.signInWithGoogle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                    Text("Sign up with Google")
                }
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("DarkGreen").opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    private func signUp() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !username.isEmpty, !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            showError = true
            errorMessage = "Please fill in all fields."
            return
        }

        Auth.auth().createUser(withEmail: trimmedEmail, password: trimmedPassword) { _, error in
            if let error = error {
                showError = true
                errorMessage = error.localizedDescription
                print("Sign up failed:", error)
            } else {
                showError = false
                errorMessage = ""

                // Set Firebase displayName = username
                if let user = Auth.auth().currentUser {
                    let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = trimmedUsername.isEmpty ? trimmedEmail : trimmedUsername

                    changeRequest.commitChanges { commitError in
                        if let commitError = commitError {
                            print("Failed to set displayName:", commitError)
                        }
                        onSignUpSuccess()
                    }
                } else {
                    onSignUpSuccess()
                }
            }
        }
    }
}


// ===============================================================
// MARK: - FORGOT PASSWORD
// ===============================================================
struct ForgotPasswordSheet: View {
    @Binding var email: String

    @Environment(\.dismiss) private var dismiss
    @State private var showError: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("LightGreen"), Color("SoftCream")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Reset Password")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("DarkGreen"))

                    Text("Enter the email associated with your account and we’ll send you a reset link.")
                        .font(.subheadline)
                        .foregroundColor(Color("DarkGreen").opacity(0.8))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("you@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                    }

                    if showError {
                        Text("Please enter an email address.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button {
                        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            showError = true
                        } else {
                            showError = false
                            Auth.auth().sendPasswordReset(withEmail: trimmed) { error in
                                if let error = error {
                                    showError = true
                                    print("Password reset error:", error)
                                } else {
                                    // success: dismiss the sheet
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        Text("Send Reset Link")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color("DarkGreen"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 4)
                    Spacer()
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("DarkGreen"))
                }
            }
        }
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
            species: "Monstera deliciosa",
            imageData: nil,
            notes: "Keep near indirect sunlight.",
            tasks: [
                PlantTask(title: "water",     reminderEnabled: true,  frequencyDays: 1,  timesPerDay: 2, waterMode: .timesPerDay),
                PlantTask(title: "fertilize", reminderEnabled: false, frequencyDays: 30, timesPerDay: 1, waterMode: .everyXDays),
                PlantTask(title: "trimming",  reminderEnabled: false, frequencyDays: 14, timesPerDay: 1, waterMode: .everyXDays)
            ]
        )
    ) { $plant in
        PlantCard(plant: $plant)
            .padding()
    }
}

#Preview("Profile") {
    ProfileView()
        .environmentObject(AuthManager())
}

