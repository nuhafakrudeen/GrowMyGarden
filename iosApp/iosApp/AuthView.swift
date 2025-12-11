import FirebaseAuth
import SwiftUI

// ===============================================================
// MARK: - AUTH VIEW (Sign In / Create Account)
// ===============================================================

/// Top-level auth screen that lets the user switch between
/// "Sign In" and "Create Account".
struct AuthView: View {
    enum Mode {
        case signIn
        case signUp
    }

    /// Which tab is active: login or signup.
    @State private var mode: Mode = .signIn

    /// Called when any auth flow finishes successfully.
    let onAuthSuccess: () -> Void

    var body: some View {
        ZStack {
            // Soft gradient background.
            LinearGradient(
                colors: [Color("LightGreen"), Color("SoftCream")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                header

                // Toggle between Sign In / Create Account.
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

                // Auth form card.
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

    /// App logo, name, and small subtitle.
    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color("DarkGreen"))

            Text("Grow My Garden")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(Color("DarkGreen"))

            Text(
                mode == .signIn
                    ? "Welcome back! Log in to continue"
                    : "Create an account to get started"
            )
            .font(.subheadline)
            .foregroundColor(Color("DarkGreen").opacity(0.8))
        }
        .padding(.top, 40)
    }

    /// Small pill-style toggle button used for Sign In / Create Account.
    private func authToggleButton(
        title: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
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

/// Email/password login + social providers.
struct SignInForm: View {
    @EnvironmentObject var auth: AuthManager

    @State private var username: String = ""       // Email
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showForgotSheet: Bool = false
    @State private var forgotEmail: String = ""

    /// Called on successful login.
    let onLoginSuccess: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Login")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("DarkGreen"))

            // Email field.
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

            // Password field.
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

            // Forgot password link.
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    forgotEmail = username
                    showForgotSheet = true
                }
                .font(.caption)
                .foregroundColor(Color("DarkGreen"))
            }

            // Login button.
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

            // Divider with "OR".
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3))

                Text("OR")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3))
            }
            .padding(.vertical, 4)

            // Continue with Apple.
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

            // Continue with Google.
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

    /// Turns Firebase error codes into human-readable messages.
    private func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError

        if let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .invalidCredential, .wrongPassword:
                return "Your email or password is incorrect. Please try again."
            case .invalidEmail:
                return "Please enter a valid email address."
            case .userNotFound:
                return "No account found with that email. Try signing up instead."
            case .networkError:
                return "Network error. Check your connection and try again."
            default:
                return "Something went wrong while signing you in. Please try again."
            }
        }

        return "Something went wrong while signing you in. Please try again."
    }

    /// Calls Firebase to sign the user in with email/password.
    private func signIn() {
        let email = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let pwd = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !email.isEmpty, !pwd.isEmpty else {
            showError = true
            errorMessage = "Please enter email and password."
            return
        }

        Auth.auth().signIn(withEmail: email, password: pwd) { _, error in
            if let error {
                showError = true
                errorMessage = friendlyMessage(for: error)
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

/// Email/password signup + Apple/Google options.
struct SignUpForm: View {
    @EnvironmentObject var auth: AuthManager

    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    /// Called after a new account is created.
    let onSignUpSuccess: () -> Void

    /// Switches the parent view back to the login tab.
    let onSwitchToLogin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create an Account")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("DarkGreen"))

            // Username.
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

            // Email.
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

            // Password.
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

            // Create account button.
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

            // Already have account → Login link.
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

            // Divider with "OR".
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3))

                Text("OR")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3))
            }
            .padding(.vertical, 4)

            // Sign up with Apple.
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

            // Sign up with Google.
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

    /// Creates a new Firebase user and sets the display name.
    private func signUp() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !username.isEmpty, !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            showError = true
            errorMessage = "Please fill in all fields."
            return
        }

        Auth.auth().createUser(withEmail: trimmedEmail, password: trimmedPassword) { _, error in
            if let error {
                showError = true
                errorMessage = error.localizedDescription
                print("Sign up failed:", error)
            } else {
                showError = false
                errorMessage = ""

                // Set Firebase displayName = username (or email as fallback).
                if let user = Auth.auth().currentUser {
                    let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = trimmedUsername.isEmpty ? trimmedEmail : trimmedUsername

                    changeRequest.commitChanges { commitError in
                        if let commitError {
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
// MARK: - FORGOT PASSWORD SHEET
// ===============================================================

/// Bottom sheet for sending a password reset link.
struct ForgotPasswordSheet: View {
    @Binding var email: String

    @Environment(\.dismiss) private var dismiss

    @State private var showMessage: Bool = false
    @State private var messageText: String = ""
    @State private var isError: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient.
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

                    Text(
                        "Enter the email associated with your account and we’ll send you a reset link."
                    )
                    .font(.subheadline)
                    .foregroundColor(Color("DarkGreen").opacity(0.8))

                    // Email field.
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

                    if showMessage {
                        Text(messageText)
                            .font(.caption)
                            .foregroundColor(isError ? .red : .green)
                    }

                    // Send reset link button.
                    Button {
                        sendReset()
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

    /// Sends the Firebase password reset email and shows a status message.
    private func sendReset() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            showMessage = true
            isError = true
            messageText = "Please enter an email address."
            return
        }

        // Clear any existing message.
        showMessage = false
        messageText = ""

        Auth.auth().sendPasswordReset(withEmail: trimmed) { error in
            if let error = error as NSError?,
               let code = AuthErrorCode(rawValue: error.code) {
                showMessage = true
                isError = true

                switch code {
                case .invalidEmail:
                    messageText = "Please enter a valid email address."
                case .networkError:
                    messageText = "Network error. Check your connection and try again."
                case .userNotFound:
                    // Firebase often returns success for this, but handle just in case.
                    messageText =
                        "If an account exists for that email, a reset link has been sent."
                default:
                    messageText = "Something went wrong. Please try again."
                }
            } else {
                // Firebase returns success even if the email is not registered.
                showMessage = true
                isError = false
                messageText =
                    "If an account exists for that email, we've sent a reset link."
            }
        }
    }
}
