import FirebaseAuth
import SwiftUI





//private struct ReminderConfigRow: View {
//    @Binding var task: PlantTask
//
//    var isWater: Bool {
//        task.title.lowercased() == "water"
//    }
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            // main toggle
//            HStack {
//                Toggle(isOn: $task.reminderEnabled) {
//                    Text(task.title.capitalized)
//                        .font(.subheadline.weight(.semibold))
//                }
//            }
//
//            if isWater {
//                // mode picker: per day vs every X days
//                Picker("Water Schedule Mode", selection: $task.waterMode) {
//                    ForEach(WaterScheduleMode.allCases) { mode in
//                        Text(mode.label).tag(mode)
//                    }
//                }
//                .pickerStyle(.segmented)
//
//                if task.waterMode == .timesPerDay {
//                    // 0 ... N times per day
//                    let label = "\(task.timesPerDay) time\(task.timesPerDay == 1 ? "" : "s") per day"
//
//                    Stepper(
//                        label,
//                        value: $task.timesPerDay,
//                        in: 0...10
//                    )
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                } else {
//                    // every X days (0 allowed)
//                    let label = "Every \(task.frequencyDays) day\(task.frequencyDays == 1 ? "" : "s")"
//
//                    Stepper(
//                        label,
//                        value: $task.frequencyDays,
//                        in: 0...60
//                    )
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                }
//            } else {
//                // fertilize / trimming: every X days, starting at 0
//                let label = "Every \(task.frequencyDays) day\(task.frequencyDays == 1 ? "" : "s")"
//
//                Stepper(
//                    label,
//                    value: $task.frequencyDays,
//                    in: 0...180
//                )
//                .font(.caption)
//                .foregroundColor(.secondary)
//            }
//        }
//        .padding(.vertical, 4)
//    }
//}

//private struct ReminderRow: View {
//    @Binding var task: PlantTask
//    let plant: Plant
//    @State private var showNotifDeniedAlert = false
//
//    var body: some View {
//        HStack(alignment: .top) {
//            VStack(alignment: .leading, spacing: 4) {
//                HStack(spacing: 8) {
//                    Text("-")
//                    Text(task.title.capitalized)
//                        .font(.system(size: 18, weight: .semibold))
//                }
//                subLabel
//            }
//            Spacer()
//            Toggle("", isOn: $task.reminderEnabled)
//                .labelsHidden()
//                .onChange(of: task.reminderEnabled) { isOn in
//                    handleToggle(isOn: isOn)
//                }
//        }
//        .alert("Notifications are Off", isPresented: $showNotifDeniedAlert) {
//            Button("Open Settings") { NotificationManager.openSettings() }
//            Button("OK", role: .cancel) { }
//        } message: {
//            Text("To receive plant reminders, enable notifications in Settings.")
//        }
//    }
//
//    private var subLabel: some View {
//        let title = task.title.lowercased()
//        let text: String
//
//        if title == "water" {
//            if task.waterMode == .timesPerDay {
//                text = "Repeats \(task.timesPerDay)x per day"
//            } else {
//                text = "Every \(task.frequencyDays) day\(task.frequencyDays == 1 ? "" : "s")"
//            }
//        } else {
//            text = "Every \(task.frequencyDays) day\(task.frequencyDays == 1 ? "" : "s")"
//        }
//
//        return Text(text)
//            .font(.caption)
//            .foregroundStyle(.secondary)
//            .padding(.leading, 16)
//            .eraseToAnyView()
//    }
//
//    private func handleToggle(isOn: Bool) {
//        let id = "\(plant.id.uuidString)::\(task.title.lowercased())"
//
//        if isOn {
//            NotificationManager.currentStatus { status in
//                switch status {
//                case .notDetermined:
//                    NotificationManager.requestAuthorization { granted in
//                        if granted {
//                            scheduleCurrentReminder(identifier: id)
//                        } else {
//                            task.reminderEnabled = false
//                            showNotifDeniedAlert = true
//                        }
//                    }
//                case .denied:
//                    task.reminderEnabled = false
//                    showNotifDeniedAlert = true
//                case .authorized, .provisional, .ephemeral:
//                    scheduleCurrentReminder(identifier: id)
//                @unknown default:
//                    task.reminderEnabled = false
//                }
//            }
//        } else {
//            NotificationManager.cancel(identifier: id)
//        }
//    }
//
//    private func scheduleCurrentReminder(identifier: String) {
//        let title = task.title.lowercased()
//        let seconds: TimeInterval
//
//        if title == "water" {
//            if task.waterMode == .timesPerDay {
//                let timesPerDay = max(task.timesPerDay, 1)
//                seconds = TimeInterval((24 * 60 * 60) / timesPerDay)
//            } else {
//                let days = max(task.frequencyDays, 1)
//                seconds = TimeInterval(days * 24 * 60 * 60)
//            }
//        } else {
//            let days = max(task.frequencyDays, 1)
//            seconds = TimeInterval(days * 24 * 60 * 60)
//        }
//
//        NotificationManager.scheduleRepeating(
//            taskTitle: task.title,
//            plantName: plant.name.isEmpty ? "your plant" : plant.name,
//            identifier: identifier,
//            intervalSeconds: seconds
//        )
//    }
//}

//private extension View { func eraseToAnyView() -> AnyView { AnyView(self) } }



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

    private func signIn() {
        let email = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let pwd   = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !email.isEmpty, !pwd.isEmpty else {
            showError = true
            errorMessage = "Please enter email and password."
            return
        }

        Auth.auth().signIn(withEmail: email, password: pwd) { _, error in
            if let error = error {
                showError = true
                errorMessage = friendlyMessage(for: error)   // custom text
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
    @State private var showMessage: Bool = false
    @State private var messageText: String = ""
    @State private var isError: Bool = false

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

                    if showMessage {
                        Text(messageText)
                            .font(.caption)
                            .foregroundColor(isError ? .red : .green)
                    }

                    Button {
                        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

                        guard !trimmed.isEmpty else {
                            showMessage = true
                            isError = true
                            messageText = "Please enter an email address."
                            return
                        }

                        // clear old message
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

                                // Firebase *rarely* sends this — usually never
                                case .userNotFound:
                                    messageText = "If an account exists for that email, a reset link has been sent."

                                default:
                                    messageText = "Something went wrong. Please try again."
                                }

                            } else {
                                // Firebase returns SUCCESS *even if the email isn’t registered*
                                showMessage = true
                                isError = false
                                messageText = "If an account exists for that email, we've sent a reset link."
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

