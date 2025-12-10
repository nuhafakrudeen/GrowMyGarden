import SwiftUI
import FirebaseCore
import Shared

// MARK: - AppDelegate

/// Helps Firebase and other libraries run code when the app starts.
final class AppDelegate: NSObject, UIApplicationDelegate {}

// MARK: - Configuration

/// Loads values from Info.plist, like API keys.
private enum AppConfig {
    
    /// Gets the Perenual API key from Info.plist.
    /// If the key is missing, the app warns you during development.
    static var perenualAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "PERENUAL_API_KEY") as? String,
              !key.isEmpty
        else {
            assertionFailure("PERENUAL_API_KEY is missing or empty in Info.plist")
            return ""
        }
        return key
    }
}

// MARK: - IOSApp

/// The main entry point of the app.
@main
struct IOSApp: App {
    
    /// Lets Firebase run setup code when the app launches.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    /// Tracks whether a user is logged in across the whole app.
    @StateObject private var authManager = AuthManager()

    /// Runs when the app starts. Sets up Firebase and the shared Kotlin code.
    init() {
        FirebaseApp.configure()

        // Pass the API key to the Kotlin shared code (Koin).
        HelperKt.doInitKoin(apiKey: AppConfig.perenualAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            // The first screen the user sees (login or home)
            AuthRootView()
                .environmentObject(authManager)
        }
    }
}
