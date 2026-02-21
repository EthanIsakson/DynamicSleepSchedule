import Foundation
import EventKit

// MARK: - DayAdjustment

struct DayAdjustment: Identifiable {
    let id = UUID()
    let date: Date
    let adjustedWakeTime: Date
    let adjustedBedtime: Date       // night before the event day
    let triggeringEventTitle: String?
    let triggeringRuleName: String?
    let source: Source

    enum Source {
        case calendarEvent
        case defaultSchedule
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter(); f.timeStyle = .short; return f
    }()

    var formattedWake: String    { Self.timeFmt.string(from: adjustedWakeTime) }
    var formattedBedtime: String { Self.timeFmt.string(from: adjustedBedtime) }
}

// MARK: - CalendarService

@MainActor
class CalendarService: ObservableObject {

    private let store = EKEventStore()

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var availableCalendars: [EKCalendar] = []
    @Published var upcomingAdjustments: [DayAdjustment] = []
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    @Published var lastError: String?

    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if isAuthorized { loadCalendars() }
    }

    var isAuthorized: Bool {
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess
        } else {
            return authorizationStatus == .authorized
        }
    }

    // MARK: - Authorization

    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await store.requestFullAccessToEvents()
                authorizationStatus = granted ? .fullAccess : .denied
            } else {
                granted = try await store.requestAccess(to: .event)
                authorizationStatus = granted ? .authorized : .denied
            }
            if granted { loadCalendars() }
            return granted
        } catch {
            authorizationStatus = .denied
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: - Calendars

    func loadCalendars() {
        availableCalendars = store.calendars(for: .event)
    }

    // MARK: - Schedule Evaluation

    func evaluateSchedule(
        rules: [EventRule],
        syncSettings: SyncSettings,
        desiredSleepHours: Double,
        weeklyDefaults: WeeklyDefaultSchedule
    ) async {
        guard isAuthorized else { return }

        isLoading = true
        lastError = nil
        defer { isLoading = false }

        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: Date())

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return }

        let activeRules = rules.filter(\.isEnabled)
        var adjustments: [DayAdjustment] = []

        for offset in 0..<syncSettings.lookAheadDays {
            guard let targetDay = calendar.date(byAdding: .day, value: offset, to: tomorrow) else { continue }
            if let adj = evaluateDay(targetDay,
                                     rules: activeRules,
                                     desiredSleepHours: desiredSleepHours,
                                     weeklyDefaults: weeklyDefaults) {
                adjustments.append(adj)
            }
        }

        upcomingAdjustments = adjustments
        lastSyncDate = Date()
    }

    // MARK: - Private

    private func evaluateDay(
        _ day: Date,
        rules: [EventRule],
        desiredSleepHours: Double,
        weeklyDefaults: WeeklyDefaultSchedule
    ) -> DayAdjustment? {
        let calendar  = Calendar.current
        let weekday   = calendar.component(.weekday, from: day)
        let startOfDay = calendar.startOfDay(for: day)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }

        // Collect only the calendars referenced by active rules
        let calIDs    = Set(rules.map(\.calendarIdentifier))
        let calendars = availableCalendars.filter { calIDs.contains($0.calendarIdentifier) }

        // Find earliest event that matches any rule
        var earliestMatch: (event: EKEvent, rule: EventRule)?

        if !calendars.isEmpty {
            let predicate = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: calendars)
            let events = store.events(matching: predicate)
                .filter { !$0.isAllDay }
                .sorted { $0.startDate < $1.startDate }

            outer: for event in events {
                for rule in rules where rule.calendarIdentifier == event.calendar.calendarIdentifier {
                    if rule.matches(eventTitle: event.title ?? "", location: event.location) {
                        if earliestMatch == nil || event.startDate < earliestMatch!.event.startDate {
                            earliestMatch = (event, rule)
                        }
                        continue outer
                    }
                }
            }
        }

        if let match = earliestMatch {
            let wakeTime = match.event.startDate.addingTimeInterval(-Double(match.rule.wakeOffsetMinutes) * 60)
            let bedtime  = wakeTime.addingTimeInterval(-desiredSleepHours * 3600)
            return DayAdjustment(
                date: day,
                adjustedWakeTime: wakeTime,
                adjustedBedtime: bedtime,
                triggeringEventTitle: match.event.title,
                triggeringRuleName: match.rule.name,
                source: .calendarEvent
            )
        }

        // Fall back to per-day default
        let dayDefault = weeklyDefaults[weekday]
        guard dayDefault.isEnabled else { return nil }

        let wakeTime = timeOnly(dayDefault.wakeTime, on: day, calendar: calendar)
        let bedtime  = timeOnly(dayDefault.bedtime,  on: calendar.date(byAdding: .day, value: -1, to: day)!, calendar: calendar)

        return DayAdjustment(
            date: day,
            adjustedWakeTime: wakeTime,
            adjustedBedtime: bedtime,
            triggeringEventTitle: nil,
            triggeringRuleName: nil,
            source: .defaultSchedule
        )
    }

    /// Combines the time-of-day from `time` with the calendar date of `day`.
    private func timeOnly(_ time: Date, on day: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: comps.hour ?? 0,
                             minute: comps.minute ?? 0,
                             second: 0,
                             of: day) ?? day
    }
}
