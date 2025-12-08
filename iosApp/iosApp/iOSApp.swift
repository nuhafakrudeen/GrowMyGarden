import SwiftUI
import FirebaseCore
import Shared

class AppDelegate: NSObject, UIApplicationDelegate {}

@main
struct iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var auth = AuthManager()

    init() {
        FirebaseApp.configure()

        // Define your API Key here (or read it from a local plist/Config file)
        let perenualKey = "sk-Ipaw69374072bba7513844"

        // Initialize the shared Kotlin DI container (Koin) with the key.
        print("👉 Calling Kotlin doInitKoin()")
        HelperKt.doInitKoin(apiKey: perenualKey)
        print("✅ Returned from Kotlin doInitKoin()")
    }

    var body: some Scene {
        WindowGroup {
            AuthRootView()
                .environmentObject(auth)
        }
    }
}
