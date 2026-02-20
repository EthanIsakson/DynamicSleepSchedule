import Foundation
import Combine

class AppSettings: ObservableObject {

    // MARK: - Notification Settings
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    @Published var showChangeSummary: Bool {
        didSet { UserDefaults.standard.set(showChangeSummary, forKey: "showChangeSummary") }
    }

    @Published var notifyHoursBeforeBedtime: Int {
        didSet { UserDefaults.standard.set(notifyHoursBeforeBedtime, forKey: "notifyHoursBeforeBedtime") }
    }

    // MARK: - Sleep Defaults
    @Published var defaultBedtime: Date {
        didSet { UserDefaults.standard.set(defaultBedtime, forKey: "defaultBedtime") }
    }

    @Published var defaultWakeTime: Date {
        didSet { UserDefaults.standard.set(defaultWakeTime, forKey: "defaultWakeTime") }
    }

    @Published var minimumSleepHours: Double {
        didSet { UserDefaults.standard.set(minimumSleepHours, forKey: "minimumSleepHours") }
    }

    // MARK: - Init
    init() {
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.showChangeSummary = UserDefaults.standard.object(forKey: "showChangeSummary") as? Bool ?? true
        self.notifyHoursBeforeBedtime = UserDefaults.standard.object(forKey: "notifyHoursBeforeBedtime") as? Int ?? 2
        self.minimumSleepHours = UserDefaults.standard.object(forKey: "minimumSleepHours") as? Double ?? 7.0

        // Default bedtime: 10:30 PM
        if let saved = UserDefaults.standard.object(forKey: "defaultBedtime") as? Date {
            self.defaultBedtime = saved
        } else {
            self.defaultBedtime = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date()
        }

        // Default wake time: 6:30 AM
        if let saved = UserDefaults.standard.object(forKey: "defaultWakeTime") as? Date {
            self.defaultWakeTime = saved
        } else {
            self.defaultWakeTime = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()) ?? Date()
        }
    }
}
