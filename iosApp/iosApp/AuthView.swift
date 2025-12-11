import SwiftUI

// ===============================================================
// MARK: - AUTH VIEW (Sign In / Create Account)
// ===============================================================

struct AuthView: View {
    enum Mode { case signIn, signUp }

    @State private var mode: Mode = .signIn
    let onAuthSuccess: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color("LightGreen"), Color("SoftCream")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // App title
                VStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color("DarkGreen"))

                    Text("Grow My Garden")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color("DarkGreen"))

                    Text(mode == .signIn ? "Welcome back! Log in to continue" :
                                            "Create an account to get started")
                        .font(.subheadline)
                        .foregroundColor(Color("DarkGreen").opacity(0.8))
                }
                .padding(.top, 40)

                // SIGN IN / CREATE ACCOUNT toggle
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

    private func authToggleButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
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
