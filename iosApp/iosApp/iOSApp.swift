import SwiftUI

@main
struct iOSApp: App {
    @StateObject private var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            AuthRootView()
                .environmentObject(auth)
        }
    }
}
