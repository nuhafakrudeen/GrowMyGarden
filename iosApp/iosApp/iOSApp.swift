import SwiftUI
import FirebaseCore
import Shared

@main
struct iOSApp: App {
    @StateObject private var auth = AuthManager()
    
    init() {
        FirebaseApp.configure()
        // Call the wrapper that delegates to initKoin()
        HelperKt.doInitKoin()
    }

    var body: some Scene {
        WindowGroup {
            AuthRootView()
                .environmentObject(auth)
        }
    }
}
