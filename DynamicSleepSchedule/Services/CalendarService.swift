import Foundation
import EventKit

/// Fetches calendar events and computes suggested sleep adjustments.
@MainActor
class CalendarService: ObservableObject {

    @Published var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @Published var pendingAdjustment: SleepAdjustment? = nil
    @Published var isLoading = false
    @Published var lastSyncDate: Date? = nil

    private let eventStore = EKEventStore()

    /// How many minutes before an event the user needs to be awake and ready.
    let preparationBufferMinutes: Int = 30

    /// How many hours ahead to scan for conflicting events.
    let lookAheadHours: Int = 36

    // MARK: - Authorization

    var isAuthorized: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            return status == .fullAccess
        }
        return status == .authorized
    }

    func requestAccess() async {
        let current = EKEventStore.authorizationStatus(for: .event)
        // Already decided — just refresh published status
        guard current == .notDetermined else {
            authorizationStatus = current
            return
        }

        do {
            if #available(iOS 17.0, *) {
                try await eventStore.requestFullAccessToEvents()
            } else {
                _ = try await eventStore.requestAccess(to: .event)
            }
        } catch {
            // User denied or an error occurred
        }

        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Sync

    func sync(settings: AppSettings) async {
        guard isAuthorized else { return }
        isLoading = true
        defer { isLoading = false }

        let now = Date()
        let end = Calendar.current.date(byAdding: .hour, value: lookAheadHours, to: now)!

        let predicate = eventStore.predicateForEvents(withStart: now, end: end, calendars: nil)
        let events = eventStore.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }

        pendingAdjustment = computeAdjustment(for: events, settings: settings)
        lastSyncDate = Date()
    }

    func dismissAdjustment() {
        pendingAdjustment = nil
    }

    // MARK: - Conflict Detection

    /// Returns a `SleepAdjustment` if any event requires waking earlier than the default schedule,
    /// or `nil` if the schedule is clear.
    ///
    /// Conflict rule: an event that starts **during the sleep window or within the
    /// preparation buffer after wake time** forces an earlier wake. The entire
    /// schedule (bedtime + wake time) is shifted earlier by the same amount so
    /// sleep duration is preserved, as long as the result still meets the user's
    /// minimum-sleep-hours requirement.
    private func computeAdjustment(for events: [EKEvent], settings: AppSettings) -> SleepAdjustment? {
        let cal = Calendar.current
        let now = Date()

        // Build tonight's sleep window from the user's stored time-of-day preferences.
        let bedComponents = cal.dateComponents([.hour, .minute], from: settings.defaultBedtime)
        let wakeComponents = cal.dateComponents([.hour, .minute], from: settings.defaultWakeTime)

        guard
            let bedtime = cal.date(
                bySettingHour: bedComponents.hour ?? 22,
                minute: bedComponents.minute ?? 30,
                second: 0, of: now),
            var wakeTime = cal.date(
                bySettingHour: wakeComponents.hour ?? 6,
                minute: wakeComponents.minute ?? 30,
                second: 0, of: now)
        else { return nil }

        // Wake time is the following morning if it falls before bedtime.
        if wakeTime <= bedtime {
            wakeTime = cal.date(byAdding: .day, value: 1, to: wakeTime)!
        }

        let original = SleepSchedule(bedtime: bedtime, wakeTime: wakeTime)
        let bufferInterval = TimeInterval(preparationBufferMinutes * 60)

        // Conflict window: (bedtime, wakeTime + preparationBuffer]
        // Events inside this window may require an earlier wake time.
        let conflictWindowEnd = wakeTime.addingTimeInterval(bufferInterval)

        var earliestRequiredWake: Date? = nil
        var triggeringEvent: EKEvent? = nil

        for event in events {
            guard let start = event.startDate else { continue }

            // Must fall inside the conflict window.
            guard start > bedtime && start <= conflictWindowEnd else { continue }

            // The user must be awake `preparationBufferMinutes` before the event.
            let requiredWake = start.addingTimeInterval(-bufferInterval)

            // Only a conflict if it forces an earlier wake than default.
            guard requiredWake < wakeTime else { continue }

            if earliestRequiredWake == nil || requiredWake < earliestRequiredWake! {
                earliestRequiredWake = requiredWake
                triggeringEvent = event
            }
        }

        guard let requiredWake = earliestRequiredWake, let event = triggeringEvent else {
            return nil
        }

        // Shift bedtime earlier by the same delta to preserve sleep duration.
        let shiftInterval = wakeTime.timeIntervalSince(requiredWake)
        let adjustedBedtime = bedtime.addingTimeInterval(-shiftInterval)
        let adjusted = SleepSchedule(bedtime: adjustedBedtime, wakeTime: requiredWake)

        // Don't suggest an adjustment that would violate the minimum sleep requirement.
        guard adjusted.durationHours >= settings.minimumSleepHours else { return nil }

        return SleepAdjustment(
            original: original,
            adjusted: adjusted,
            triggeringEventTitle: event.title ?? "Untitled Event",
            triggeringEventDate: event.startDate,
            direction: .earlier
        )
    }
}
