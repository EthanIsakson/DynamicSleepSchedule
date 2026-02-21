import Foundation

enum SyncFrequency: String, Codable, CaseIterable {
    case onceDaily      = "Once Daily"
    case twiceDaily     = "Twice Daily"
    case everySixHours  = "Every 6 Hours"
    case everyThreeHours = "Every 3 Hours"

    var intervalSeconds: TimeInterval {
        switch self {
        case .onceDaily:       return 86400
        case .twiceDaily:      return 43200
        case .everySixHours:   return 21600
        case .everyThreeHours: return 10800
        }
    }
}

struct SyncSettings: Codable, Equatable {
    var lookAheadDays: Int = 7
    var syncTime: Date
    var frequency: SyncFrequency = .onceDaily

    init() {
        syncTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    }
}
