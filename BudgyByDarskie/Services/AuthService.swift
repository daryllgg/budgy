import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

@Observable
class AuthService {
    nonisolated(unsafe) static let shared = AuthService()

    var user: User?
    var isAuthenticated: Bool { user != nil }
    var isLoading = true

    private var handle: AuthStateDidChangeListenerHandle?

    private init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isLoading = false
        }
    }

    var uid: String? { user?.uid }

    func signInWithGoogle(loginHint: String? = nil) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingClientID
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = await windowScene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC, hint: loginHint)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingIDToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        try await Auth.auth().signIn(with: credential)
    }

    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    func switchAccount() async throws {
        try Auth.auth().signOut()
        // Don't sign out of Google — keeps the session alive
        // so the account picker appears directly without the
        // "google.com wants to use..." permission prompt
        try await signInWithGoogle()
    }

    enum AuthError: LocalizedError {
        case missingClientID, noRootViewController, missingIDToken
        var errorDescription: String? {
            switch self {
            case .missingClientID: "Firebase client ID not found"
            case .noRootViewController: "No root view controller found"
            case .missingIDToken: "Google ID token missing"
            }
        }
    }
}
