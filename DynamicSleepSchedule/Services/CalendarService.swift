import Foundation
import EventKit

/// Fetches calendar events and computes suggested sleep adjustments.
@MainActor
class CalendarService: ObservableObject {

    @Published var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    /// One entry per night in the look-ahead window that has a conflict-driven adjustment.
    @Published var scheduleSummary: [DaySchedule] = []
    @Published var isLoading = false
    @Published var lastSyncDate: Date? = nil

    private let eventStore = EKEventStore()


    // MARK: - Authorization

    var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    func requestAccess() async {
        let current = EKEventStore.authorizationStatus(for: .event)
        guard current == .notDetermined else {
            authorizationStatus = current
            return
        }

        do {
            try await eventStore.requestFullAccessToEvents()
        } catch {
            // User denied or an error occurred.
        }

        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Sync

    func sync(settings: AppSettings) async {
        guard isAuthorized else { return }
        isLoading = true
        defer { isLoading = false }

        let cal = Calendar.current
        let now = Date()
        let end = cal.date(byAdding: .day, value: settings.eventLookAheadDays, to: now)!

        let predicate = eventStore.predicateForEvents(withStart: now, end: end, calendars: nil)
        let allEvents = eventStore.events(matching: predicate)
            .filter { !$0.isAllDay }
            .filter { event in
                guard !settings.eventFilters.isEmpty else { return true }
                let title    = event.title ?? ""
                let calName  = event.calendar?.title ?? ""
                return settings.eventFilters.allSatisfy { $0.matches(title: title, calendarName: calName) }
            }
            .sorted { $0.startDate < $1.startDate }

        // Compute one DaySchedule per night in the look-ahead window.
        // Only nights with a conflict-driven adjustment are kept.
        var summary: [DaySchedule] = []
        for offset in 0..<settings.eventLookAheadDays {
            guard let nightDate = cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: now)) else { continue }
            let day = computeNightSchedule(nightDate: nightDate, events: allEvents, settings: settings)
            if day.isAdjusted {
                summary.append(day)
            }
        }

        scheduleSummary = summary
        lastSyncDate = Date()
    }

    // MARK: - Conflict Detection

    /// Builds a `DaySchedule` for a single night.
    ///
    /// Conflict rule: an event that starts **during the sleep window or within the
    /// preparation buffer after wake time** forces an earlier wake. The entire
    /// schedule (bedtime + wake time) is shifted earlier by the same amount so
    /// sleep duration is preserved, provided the result still meets the user's
    /// minimum-sleep-hours requirement.
    private func computeNightSchedule(nightDate: Date, events: [EKEvent], settings: AppSettings) -> DaySchedule {
        let cal = Calendar.current

        let bedComponents  = cal.dateComponents([.hour, .minute], from: settings.defaultBedtime)
        let wakeComponents = cal.dateComponents([.hour, .minute], from: settings.defaultWakeTime)

        // Default sleep window for this specific night
        let bedtime = cal.date(
            bySettingHour: bedComponents.hour  ?? 22,
            minute:        bedComponents.minute ?? 30,
            second: 0, of: nightDate) ?? nightDate

        var wakeTime = cal.date(
            bySettingHour: wakeComponents.hour  ?? 6,
            minute:        wakeComponents.minute ?? 30,
            second: 0, of: nightDate) ?? nightDate

        // Wake time is the following morning if it falls before or at bedtime.
        if wakeTime <= bedtime {
            wakeTime = cal.date(byAdding: .day, value: 1, to: wakeTime) ?? wakeTime
        }

        let defaultSchedule = SleepSchedule(bedtime: bedtime, wakeTime: wakeTime)
        let bufferInterval  = TimeInterval(settings.wakeOffsetMinutes * 60)
        let conflictWindowEnd = wakeTime.addingTimeInterval(bufferInterval)

        // Find the event requiring the earliest wake time within the conflict window.
        var earliestRequiredWake: Date? = nil
        var triggeringEvent: EKEvent? = nil

        for event in events {
            guard let start = event.startDate else { continue }
            guard start > bedtime && start <= conflictWindowEnd else { continue }

            let requiredWake = start.addingTimeInterval(-bufferInterval)
            guard requiredWake < wakeTime else { continue }

            if earliestRequiredWake == nil || requiredWake < earliestRequiredWake! {
                earliestRequiredWake = requiredWake
                triggeringEvent = event
            }
        }

        guard let requiredWake = earliestRequiredWake, let event = triggeringEvent else {
            return DaySchedule(date: nightDate, defaultSchedule: defaultSchedule, adjustment: nil)
        }

        let shiftInterval   = wakeTime.timeIntervalSince(requiredWake)
        let adjustedBedtime = bedtime.addingTimeInterval(-shiftInterval)
        let adjusted        = SleepSchedule(bedtime: adjustedBedtime, wakeTime: requiredWake)

        // Suppress if the shift would violate minimum sleep hours.
        guard adjusted.durationHours >= settings.minimumSleepHours else {
            return DaySchedule(date: nightDate, defaultSchedule: defaultSchedule, adjustment: nil)
        }

        let adjustment = SleepAdjustment(
            original: defaultSchedule,
            adjusted: adjusted,
            triggeringEventTitle: event.title ?? "Untitled Event",
            triggeringEventDate:  event.startDate,
            direction: .earlier
        )

        return DaySchedule(date: nightDate, defaultSchedule: defaultSchedule, adjustment: adjustment)
    }
}
