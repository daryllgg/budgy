import SwiftUI

@Observable
class AppearanceManager {
    enum Mode: String, CaseIterable {
        case system, light, dark

        var label: String {
            switch self {
            case .system: "System"
            case .light: "Light"
            case .dark: "Dark"
            }
        }

        var icon: String {
            switch self {
            case .system: "circle.lefthalf.filled"
            case .light: "sun.max.fill"
            case .dark: "moon.fill"
            }
        }
    }

    var selectedMode: Mode {
        didSet {
            UserDefaults.standard.set(selectedMode.rawValue, forKey: "appearanceMode")
        }
    }

    var hideValues: Bool {
        didSet {
            UserDefaults.standard.set(hideValues, forKey: "hideValues")
        }
    }

    var colorScheme: ColorScheme? {
        switch selectedMode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    func maskedValue(_ value: String) -> String {
        hideValues ? "••••••" : value
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        self.selectedMode = Mode(rawValue: saved) ?? .system
        self.hideValues = UserDefaults.standard.bool(forKey: "hideValues")
    }
}
