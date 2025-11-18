import SwiftUI
import FirebaseCore
import Shared

@main
struct iOSApp: App {
    @StateObject private var auth = AuthManager()
    
    init() {
        FirebaseApp.configure()
        // Initialize the shared Kotlin DI container (Koin).
        print("👉 Calling Kotlin doInitKoin()")
        HelperKt.doInitKoin()
        print("✅ Returned from Kotlin doInitKoin()")
    }

    var body: some Scene {
        WindowGroup {
            AuthRootView()
                .environmentObject(auth)
        }
    }
}
