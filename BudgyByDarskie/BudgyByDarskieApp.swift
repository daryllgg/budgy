import SwiftUI
import FirebaseCore
import GoogleSignIn
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

@main
struct BudgyByDarskieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appearanceManager = AppearanceManager()
    @State private var toastManager = ToastManager()
    @State private var navigationManager = NavigationManager()
    @State private var notificationManager = NotificationManager()
    @State private var networkMonitor = NetworkMonitor()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appearanceManager)
                .environment(toastManager)
                .environment(navigationManager)
                .environment(notificationManager)
                .environment(networkMonitor)
                .preferredColorScheme(appearanceManager.colorScheme)
        }
    }
}

// Handle Google Sign-In URL callback
extension BudgyByDarskieApp {
    static func handleOpenURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
