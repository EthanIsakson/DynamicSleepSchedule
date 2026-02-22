import Foundation

struct SleepSchedule {
    var bedtime: Date
    var wakeTime: Date

    var durationHours: Double {
        let diff = wakeTime.timeIntervalSince(bedtime)
        // Wake time may be the following morning, so add 24h if negative
        return (diff < 0 ? diff + 86400 : diff) / 3600
    }

    var formattedBedtime: String  { SleepSchedule.timeFormatter.string(from: bedtime) }
    var formattedWakeTime: String { SleepSchedule.timeFormatter.string(from: wakeTime) }

    /// Uses .timeStyle = .short so it respects the device 12 h / 24 h preference.
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

    /// How many minutes the schedule shifted (negative = earlier).
    var bedtimeShiftMinutes: Int {
        Int(adjusted.bedtime.timeIntervalSince(original.bedtime) / 60)
    }

    var wakeShiftMinutes: Int {
        Int(adjusted.wakeTime.timeIntervalSince(original.wakeTime) / 60)
    }

    /// Human-readable shift magnitude, e.g. "1 hr 30 min" or "45 min".
    var shiftLabel: String {
        let total = abs(bedtimeShiftMinutes)
        let hrs  = total / 60
        let mins = total % 60
        switch (hrs, mins) {
        case (0, _):  return "\(mins) min"
        case (_, 0):  return "\(hrs) hr"
        default:      return "\(hrs) hr \(mins) min"
        }
    }

    var summaryText: String {
        "Move bedtime \(shiftLabel) \(direction.label) for \"\(triggeringEventTitle)\""
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

// MARK: - Event Filter

/// A filter applied to calendar events before conflict detection.
/// Can match on either the event title or the calendar name.
struct EventFilter: Identifiable, Codable {
    var id: UUID

    enum Field: String, CaseIterable, Codable {
        case eventName    = "Event"
        case calendarName = "Calendar"
    }

    enum Operator: String, CaseIterable, Codable {
        case contains       = "contains"
        case doesNotContain = "doesn't contain"
        case equals         = "equals"
        case doesNotEqual   = "doesn't equal"
    }

    var field: Field
    var op: Operator
    var value: String

    init(id: UUID = UUID(), field: Field = .eventName, op: Operator = .contains, value: String = "") {
        self.id    = id
        self.field = field
        self.op    = op
        self.value = value
    }

    /// Returns `true` if the event satisfies this filter condition.
    /// An empty `value` always passes so partially-entered filters don't block everything.
    func matches(title: String, calendarName: String) -> Bool {
        guard !value.isEmpty else { return true }
        let subject = field == .eventName ? title : calendarName
        switch op {
        case .contains:       return subject.localizedCaseInsensitiveContains(value)
        case .doesNotContain: return !subject.localizedCaseInsensitiveContains(value)
        case .equals:         return subject.localizedCaseInsensitiveCompare(value) == .orderedSame
        case .doesNotEqual:   return subject.localizedCaseInsensitiveCompare(value) != .orderedSame
        }
    }
}
