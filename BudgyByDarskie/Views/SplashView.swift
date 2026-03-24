import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(AppTheme.accent)
                    .scaleEffect(scale)

                VStack(spacing: 6) {
                    Text("Budgy")
                        .font(.system(size: 32, weight: .bold, design: .rounded))

                    Text("by Darskie")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1
                scale = 1
            }
        }
    }
}
