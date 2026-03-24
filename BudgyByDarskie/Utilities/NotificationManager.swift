import Foundation
import UIKit
import UserNotifications

struct ReminderTime: Codable, Identifiable, Equatable {
    var id: String { "\(hour):\(minute)" }
    var hour: Int
    var minute: Int

    var displayTime: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", h, minute, period)
    }

    var asDate: Date {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }
}

@Observable
class NotificationManager {
    private static let storageKey = "expenseReminderTimes"
    private static let enabledKey = "expenseRemindersEnabled"

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if isEnabled {
                scheduleReminders()
            } else {
                removeAllReminders()
            }
        }
    }

    var reminderTimes: [ReminderTime] {
        didSet {
            if let data = try? JSONEncoder().encode(reminderTimes) {
                UserDefaults.standard.set(data, forKey: Self.storageKey)
            }
            if isEnabled { scheduleReminders() }
        }
    }

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let times = try? JSONDecoder().decode([ReminderTime].self, from: data) {
            self.reminderTimes = times
        } else {
            self.reminderTimes = [
                ReminderTime(hour: 8, minute: 0),
                ReminderTime(hour: 12, minute: 0),
                ReminderTime(hour: 16, minute: 0),
                ReminderTime(hour: 20, minute: 0),
            ]
        }
    }

    private let messages = [
        "This is a reminder to track and sync your finances!",
        "Have you logged your recent spending? Keep your budget accurate!",
        "Stay on top of your money — record your latest transactions!",
        "A quick check-in: any expenses to log today?",
        "Your finances won't track themselves — take a moment to update!",
    ]

    func requestPermissionAndEnable() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    self.isEnabled = true
                }
            }
        }
    }

    func addReminder(hour: Int, minute: Int) {
        let newTime = ReminderTime(hour: hour, minute: minute)
        guard !reminderTimes.contains(newTime) else { return }
        var times = reminderTimes
        times.append(newTime)
        times.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
        reminderTimes = times
    }

    func removeReminder(_ time: ReminderTime) {
        var times = reminderTimes
        times.removeAll { $0 == time }
        reminderTimes = times
    }

    func scheduleReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for time in reminderTimes {
            let content = UNMutableNotificationContent()
            content.title = "Budgy"
            content.body = messages.randomElement() ?? messages[0]
            content.sound = .default
            if let attachment = notificationIconAttachment() {
                content.attachments = [attachment]
            }

            var dateComponents = DateComponents()
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "expenseReminder_\(time.hour)_\(time.minute)",
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    private func notificationIconAttachment() -> UNNotificationAttachment? {
        // App icons can't be loaded via UIImage(named:) — use bundle icons key
        var icon: UIImage?
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let name = files.last {
            icon = UIImage(named: name)
        }
        // Fallback: load the PNG directly from the bundle
        if icon == nil, let path = Bundle.main.path(forResource: "AppIcon", ofType: "png") {
            icon = UIImage(contentsOfFile: path)
        }
        guard let icon, let data = icon.pngData() else { return nil }
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        do {
            try data.write(to: fileURL)
            return try UNNotificationAttachment(identifier: "appIcon", url: fileURL, options: nil)
        } catch {
            return nil
        }
    }

    private func removeAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
