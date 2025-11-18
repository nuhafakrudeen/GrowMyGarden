import SwiftUI
import FirebaseCore

@main
struct iOSApp: App {
    @StateObject private var auth = AuthManager()
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AuthRootView()
                .environmentObject(auth)
        }
    }
}
