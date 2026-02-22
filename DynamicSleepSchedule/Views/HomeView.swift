import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var calendarService: CalendarService

    @State private var scheduleApplied = false

    private var currentSchedule: SleepSchedule {
        SleepSchedule(bedtime: settings.defaultBedtime, wakeTime: settings.defaultWakeTime)
    }

    private var activeSchedule: SleepSchedule {
        if scheduleApplied, let adj = calendarService.pendingAdjustment {
            return adj.adjusted
        }
        return currentSchedule
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Calendar permission prompt
                    if !calendarService.isAuthorized {
                        calendarPermissionView
                    }

                    // Active schedule card
                    SleepCardView(
                        title: scheduleApplied ? "Adjusted Schedule" : "Tonight's Schedule",
                        schedule: activeSchedule
                    )

                    // Original schedule (shown dimmed when adjustment is applied)
                    if scheduleApplied, let adj = calendarService.pendingAdjustment {
                        SleepCardView(
                            title: "Original Schedule",
                            schedule: adj.original,
                            dimmed: true
                        )
                    }

                    // Adjustment banner
                    if !scheduleApplied, let adj = calendarService.pendingAdjustment {
                        AdjustmentBannerView(
                            adjustment: adj,
                            onAccept: {
                                withAnimation { scheduleApplied = true }
                            },
                            onDismiss: {
                                withAnimation { calendarService.dismissAdjustment() }
                            }
                        )
                    }

                    // Applied confirmation
                    if scheduleApplied {
                        appliedConfirmationView
                    }

                    // Empty state
                    if calendarService.pendingAdjustment == nil && !scheduleApplied && calendarService.isAuthorized {
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
                        Task { await calendarService.sync(settings: settings) }
                    } label: {
                        if calendarService.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(calendarService.isLoading || !calendarService.isAuthorized)
                }
            }
            .task {
                await calendarService.requestAccess()
                if calendarService.isAuthorized {
                    await calendarService.sync(settings: settings)
                }
            }
        }
    }

    // MARK: - Sub-views

    private var calendarPermissionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("Calendar Access Needed")
                .font(.headline)
            Text("Allow access so the app can detect conflicts between your events and sleep window.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Grant Access") {
                Task { await calendarService.requestAccess() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }

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
            if let lastSync = calendarService.lastSyncDate {
                Text("Last checked \(lastSync.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppSettings())
        .environmentObject(CalendarService())
}
