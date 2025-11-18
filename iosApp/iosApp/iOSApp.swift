import SwiftUI
import FirebaseCore
import Shared

@main
struct iOSApp: App {
    @StateObject private var auth = AuthManager()
    
    init() {
        FirebaseApp.configure()

        print("👉 Calling Kotlin initKoin")
        HelperKt.doInitKoin()
        print("✅ Finished calling Kotlin initKoin")
    }


    var body: some Scene {
        WindowGroup {
            AuthRootView()
                .environmentObject(auth)
        }
    }
}
