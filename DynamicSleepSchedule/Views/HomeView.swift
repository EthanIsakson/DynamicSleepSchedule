import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings

    // Placeholder state — will be driven by CalendarService in Phase 2
    @State private var pendingAdjustment: SleepAdjustment? = Self.mockAdjustment()
    @State private var scheduleApplied = false

    private var currentSchedule: SleepSchedule {
        SleepSchedule(bedtime: settings.defaultBedtime, wakeTime: settings.defaultWakeTime)
    }

    private var activeSchedule: SleepSchedule {
        scheduleApplied ? (pendingAdjustment?.adjusted ?? currentSchedule) : currentSchedule
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Active schedule card
                    SleepCardView(
                        title: scheduleApplied ? "Adjusted Schedule" : "Tonight's Schedule",
                        schedule: activeSchedule
                    )

                    // Original schedule (shown dimmed when adjustment is active)
                    if scheduleApplied, let adj = pendingAdjustment {
                        SleepCardView(
                            title: "Original Schedule",
                            schedule: adj.original,
                            dimmed: true
                        )
                    }

                    // Adjustment banner
                    if !scheduleApplied, let adj = pendingAdjustment {
                        AdjustmentBannerView(
                            adjustment: adj,
                            onAccept: {
                                withAnimation { scheduleApplied = true }
                            },
                            onDismiss: {
                                withAnimation { pendingAdjustment = nil }
                            }
                        )
                    }

                    // Applied confirmation
                    if scheduleApplied {
                        appliedConfirmationView
                    }

                    // Empty state
                    if pendingAdjustment == nil && !scheduleApplied {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("Sleep Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Phase 2: manual calendar refresh
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }

    // MARK: - Sub-views

    private var appliedConfirmationView: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep Focus Updated")
                    .font(.headline)
                Text("Your schedule has been adjusted.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Undo") {
                withAnimation { scheduleApplied = false }
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(.indigo.opacity(0.6))
            Text("You're all set")
                .font(.headline)
            Text("No upcoming events affect your sleep schedule.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Mock data (replaced by CalendarService in Phase 2)

    static func mockAdjustment() -> SleepAdjustment {
        let cal = Calendar.current
        let tonight = cal.date(bySettingHour: 22, minute: 30, second: 0, of: Date())!
        let tomorrow630 = cal.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!
        let earlyMeeting = cal.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!

        let original = SleepSchedule(bedtime: tonight, wakeTime: tomorrow630)
        let adjusted = SleepSchedule(
            bedtime: cal.date(byAdding: .minute, value: -30, to: tonight)!,
            wakeTime: cal.date(byAdding: .minute, value: -30, to: tomorrow630)!
        )
        return SleepAdjustment(
            original: original,
            adjusted: adjusted,
            triggeringEventTitle: "Team Standup",
            triggeringEventDate: earlyMeeting,
            direction: .earlier
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(AppSettings())
}
