import SwiftUI

public struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var username = ""
    @State private var password = ""
    @State private var shakeOffset: CGFloat = 0

    public var body: some View {
        VStack {
            Spacer(minLength: 16)

            VStack(spacing: 24) {

                VStack(spacing: 12) {

                    Text("Luxe Maison")
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .tracking(6)
                        .foregroundColor(MatteTheme.Colors.primaryGold)

                    Text("Authentication Portal")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(MatteTheme.Colors.textPrimary)
                }

                VStack(spacing: 16) {

                    VStack(alignment: .leading, spacing: 8) {

                        GlassTextField(
                            placeholder: "Username",
                            text: $username,
                            textContentType: .username
                        )

                        Text("Default admin: Admin")
                            .font(.caption)
                            .foregroundColor(MatteTheme.Colors.textPrimary)
                            .padding(.leading, 4)
                    }

                    GlassTextField(
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        textContentType: .password
                    )
                }

                if case let .failed(errorMsg) = authManager.authState {
                    Text(errorMsg)
                        .font(.callout)
                        .foregroundColor(MatteTheme.Colors.error)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }

                MatteButton(
                    title: "Sign In",
                    action: {
                        Task {
                            await authManager.login(
                                username: username,
                                password: password
                            )
                        }
                    },
                    isLoading: {
                        if case .authenticating = authManager.authState {
                            return true
                        }
                        return false
                    }()
                )
            }
            .padding(24)
            .frame(maxWidth: 420)

            .background {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.black.opacity(0.16))
                    .glassEffect(
                        .regular,
                        in: RoundedRectangle(cornerRadius: 32, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.22), radius: 24, y: 12)
            }

            .offset(x: shakeOffset)

            .offset(x: shakeOffset)
            .onChange(of: authManager.authState) { _, newState in
                if case .failed = newState {
                    triggerShake()
                }
            }

            Spacer(minLength: 20)
        }
        .safeAreaPadding(.horizontal, 16)
        .safeAreaPadding(.vertical, 20)
        .background(
            Image("login")
                .resizable()
                .interpolation(.high)
                .ignoresSafeArea(edges: .all)
                .scaledToFill()
        )
    }

    private func triggerShake() {
        let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
        impactHeavy.impactOccurred()

        withAnimation(.default) {
            shakeOffset = -10
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.default) {
                shakeOffset = 10
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.default) {
                    shakeOffset = -10
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.default) {
                        shakeOffset = 0
                    }
                }
            }
        }
    }
}
