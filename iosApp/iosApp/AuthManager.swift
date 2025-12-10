import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import Shared
import SwiftUI
import UIKit

// shared auth state for the app
final class AuthManager: NSObject, ObservableObject {
    @Published var isLoggedIn: Bool = false

    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    fileprivate var currentNonce: String?

    // 1. Get reference to Kotlin ViewModel so we can set the User ID
    private let dashboardViewModel = HelperKt.getDashboardViewModel()

    override init() {
        super.init()

        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let user = user {
                    // 2. User Logged In: Tell Kotlin the UID
                    print("🔵 User logged in: \(user.uid). Syncing with Kotlin DB.")
                    self.dashboardViewModel.setUserId(userId: user.uid)
                    self.isLoggedIn = true
                } else {
                    // 3. User Logged Out: Tell Kotlin to clear data
                    print("🔴 User logged out. Clearing Kotlin DB scope.")
                    self.dashboardViewModel.setUserId(userId: nil)
                    self.isLoggedIn = false
                }
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
            // The listener above will trigger and set vm.setUserId(nil) automatically
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
