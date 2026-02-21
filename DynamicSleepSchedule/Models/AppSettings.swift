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

    // MARK: - Sleep Goal
    @Published var desiredSleepHours: Double {
        didSet { UserDefaults.standard.set(desiredSleepHours, forKey: "desiredSleepHours") }
    }

    // MARK: - Rules
    @Published var rules: [EventRule] {
        didSet { saveJSON(rules, forKey: "rules") }
    }

    // MARK: - Weekly Default Schedule
    @Published var weeklyDefaults: WeeklyDefaultSchedule {
        didSet { saveJSON(weeklyDefaults, forKey: "weeklyDefaults") }
    }

    // MARK: - Sync Settings
    @Published var syncSettings: SyncSettings {
        didSet { saveJSON(syncSettings, forKey: "syncSettings") }
    }

    // MARK: - Init
    init() {
        self.notificationsEnabled     = UserDefaults.standard.object(forKey: "notificationsEnabled")     as? Bool   ?? true
        self.showChangeSummary        = UserDefaults.standard.object(forKey: "showChangeSummary")        as? Bool   ?? true
        self.notifyHoursBeforeBedtime = UserDefaults.standard.object(forKey: "notifyHoursBeforeBedtime") as? Int    ?? 2
        self.desiredSleepHours        = UserDefaults.standard.object(forKey: "desiredSleepHours")        as? Double ?? 8.0

        self.rules          = loadJSON([EventRule].self,           forKey: "rules")          ?? []
        self.weeklyDefaults = loadJSON(WeeklyDefaultSchedule.self, forKey: "weeklyDefaults") ?? .makeDefault()
        self.syncSettings   = loadJSON(SyncSettings.self,          forKey: "syncSettings")   ?? SyncSettings()
    }

    // MARK: - JSON Helpers
    private func saveJSON<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadJSON<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
