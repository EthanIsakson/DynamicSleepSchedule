import Foundation

struct SleepSchedule {
    var bedtime: Date
    var wakeTime: Date

    var durationHours: Double {
        let diff = wakeTime.timeIntervalSince(bedtime)
        // Wake time may be the following morning, so add 24h if negative
        return (diff < 0 ? diff + 86400 : diff) / 3600
    }

    var formattedBedtime: String { SleepSchedule.timeFormatter.string(from: bedtime) }
    var formattedWakeTime: String { SleepSchedule.timeFormatter.string(from: wakeTime) }
    var formattedDuration: String { String(format: "%.1f hrs", durationHours) }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}

struct SleepAdjustment {
    enum Direction {
        case earlier, later
        var label: String { self == .earlier ? "earlier" : "later" }
    }

    let original: SleepSchedule
    let adjusted: SleepSchedule
    let triggeringEventTitle: String
    let triggeringEventDate: Date
    let direction: Direction

    /// How many minutes the schedule shifted
    var bedtimeShiftMinutes: Int {
        Int(adjusted.bedtime.timeIntervalSince(original.bedtime) / 60)
    }

    var wakeShiftMinutes: Int {
        Int(adjusted.wakeTime.timeIntervalSince(original.wakeTime) / 60)
    }

    var summaryText: String {
        let absShift = abs(bedtimeShiftMinutes)
        return "Move bedtime \(absShift) min \(direction.label) for \"\(triggeringEventTitle)\""
    }
}

// MARK: - Day Schedule

/// The resolved schedule for a single night — default plus any conflict-driven adjustment.
struct DaySchedule: Identifiable {
    var id: Date { date }
    /// The calendar date on which the person goes to sleep (start of that day).
    let date: Date
    let defaultSchedule: SleepSchedule
    /// Non-nil when a calendar event forces an earlier wake that night.
    let adjustment: SleepAdjustment?

    var isAdjusted: Bool { adjustment != nil }
    var activeSchedule: SleepSchedule { adjustment?.adjusted ?? defaultSchedule }
}

// MARK: - Event Name Filter

/// A single name-based filter applied to calendar events before conflict detection.
struct EventFilter: Identifiable, Codable {
    var id: UUID

    enum Operator: String, CaseIterable, Codable {
        case contains       = "contains"
        case doesNotContain = "doesn't contain"
        case equals         = "equals"
        case doesNotEqual   = "doesn't equal"
    }

    var op: Operator
    var value: String

    init(id: UUID = UUID(), op: Operator = .contains, value: String = "") {
        self.id = id
        self.op = op
        self.value = value
    }

    /// Returns `true` if the event title satisfies this filter condition.
    /// An empty `value` always passes so partially-entered filters don't block everything.
    func matches(_ title: String) -> Bool {
        guard !value.isEmpty else { return true }
        switch op {
        case .contains:       return title.localizedCaseInsensitiveContains(value)
        case .doesNotContain: return !title.localizedCaseInsensitiveContains(value)
        case .equals:         return title.localizedCaseInsensitiveCompare(value) == .orderedSame
        case .doesNotEqual:   return title.localizedCaseInsensitiveCompare(value) != .orderedSame
        }
    }
}

