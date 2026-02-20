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
