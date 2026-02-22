import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

/// Provides the foundation for hooking into iOS Focus – Sleep.
///
/// When the HealthKit capability is enabled in the Xcode project
/// (Signing & Capabilities → + Capability → HealthKit), this service
/// writes upcoming adjusted sleep windows to the Health store. iOS uses
/// that data to surface accurate bedtime / wake-up times inside the
/// Sleep Focus schedule.
///
/// **Setup checklist (one-time, done in Xcode):**
/// 1. Add the HealthKit capability to the target.
/// 2. Add `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription`
///    to Info.plist (already present — see below).
/// 3. Call `requestAuthorization()` before the first `writeSleepSchedule(_:)`.
@MainActor
final class FocusSleepService: ObservableObject {

#if canImport(HealthKit)
    private let store = HKHealthStore()
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
#endif

    /// `true` once the user has granted write access to sleep analysis data.
    @Published var isAuthorized = false

    /// `false` on simulators and devices where HealthKit is unavailable.
    var isAvailable: Bool {
#if canImport(HealthKit)
        return HKHealthStore.isHealthDataAvailable()
#else
        return false
#endif
    }

    // MARK: - Authorization

    func requestAuthorization() async {
#if canImport(HealthKit)
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [sleepType], read: [])
            isAuthorized = store.authorizationStatus(for: sleepType) == .sharingAuthorized
        } catch {
            isAuthorized = false
        }
#endif
    }

    // MARK: - Write Sleep Windows

    /// Writes upcoming adjusted sleep windows to HealthKit as "in bed" samples.
    ///
    /// These appear in Health → Browse → Sleep and feed into the Sleep Focus
    /// schedule so the system can remind the user of the adjusted bedtime.
    func writeSleepSchedule(_ days: [DaySchedule]) async {
#if canImport(HealthKit)
        guard isAuthorized, !days.isEmpty else { return }

        // Remove any previously written app-managed samples for the same nights
        // so re-syncing doesn't produce duplicates.
        let starts = days.map { $0.activeSchedule.bedtime }
        let ends   = days.map { $0.activeSchedule.wakeTime }
        if let earliest = starts.min(), let latest = ends.max() {
            let predicate = HKQuery.predicateForSamples(withStart: earliest, end: latest)
            let sourcePredicate = HKQuery.predicateForObjects(from: .default())
            let combined = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, sourcePredicate])
            _ = try? await store.delete(
                HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!,
                predicate: combined
            )
        }

        let samples: [HKSample] = days.compactMap { day in
            let schedule = day.activeSchedule
            guard schedule.wakeTime > schedule.bedtime else { return nil }
            return HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.inBed.rawValue,
                start: schedule.bedtime,
                end:   schedule.wakeTime
            )
        }

        guard !samples.isEmpty else { return }
        _ = try? await store.save(samples)
#endif
    }
}
