import Foundation

@Observable
class AuthViewModel {
    private let auth = AuthService.shared

    var isAuthenticated: Bool { auth.isAuthenticated }
    var isLoading: Bool { auth.isLoading }
    var uid: String? { auth.uid }
    var displayName: String { auth.user?.displayName ?? "" }
    var email: String { auth.user?.email ?? "" }
    var photoURL: URL? { auth.user?.photoURL }

    var errorMessage: String?

    func signIn() async {
        errorMessage = nil
        do {
            try await auth.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try auth.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func switchAccount() async {
        errorMessage = nil
        do {
            try await auth.switchAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
