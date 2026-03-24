import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.colorScheme) private var colorScheme
    @State private var isSigningIn = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: AppTheme.loginGradient(for: colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 100, height: 100)
                        .glassEffect(.regular, in: .circle)

                    VStack(spacing: 8) {
                        Text("Budgy")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Track your money, grow your wealth")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
                Spacer()

                VStack(spacing: 20) {
                    Button {
                        isSigningIn = true
                        Task {
                            await authVM.signIn()
                            isSigningIn = false
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "person.circle.fill")
                                .font(.title3)
                            Text("Sign in with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(AppTheme.accent)
                    .disabled(isSigningIn)

                    if isSigningIn {
                        ProgressView()
                            .tint(AppTheme.accent)
                    }

                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
    }
}
