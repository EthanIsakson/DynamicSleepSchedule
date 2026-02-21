import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var calendarService: CalendarService
    @State private var dismissedIDs: Set<UUID> = []

    private var visibleAdjustments: [DayAdjustment] {
        calendarService.upcomingAdjustments.filter { !dismissedIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Calendar auth prompt
                    if !calendarService.isAuthorized {
                        calendarAccessBanner
                    }

                    // No rules configured yet
                    if calendarService.isAuthorized && settings.rules.isEmpty {
                        noRulesState
                    }

                    // Upcoming adjustments
                    if !visibleAdjustments.isEmpty {
                        ForEach(Array(visibleAdjustments.enumerated()), id: \.element.id) { index, adj in
                            AdjustmentCardView(
                                adjustment: adj,
                                featured: index == 0,
                                onDismiss: { withAnimation { dismissedIDs.insert(adj.id) } }
                            )
                        }
                    }

                    // All clear
                    if calendarService.isAuthorized
                        && !settings.rules.isEmpty
                        && visibleAdjustments.isEmpty
                        && !calendarService.isLoading {
                        allClearView
                    }

                    // Last sync footer
                    if let lastSync = calendarService.lastSyncDate {
                        lastSyncLabel(lastSync)
                    }
                }
                .padding()
            }
            .navigationTitle("Sleep Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await calendarService.evaluateSchedule(
                                rules: settings.rules,
                                syncSettings: settings.syncSettings,
                                desiredSleepHours: settings.desiredSleepHours,
                                weeklyDefaults: settings.weeklyDefaults
                            )
                        }
                    } label: {
                        if calendarService.isLoading {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(calendarService.isLoading)
                }
            }
            .task {
                // Run initial evaluation when view appears
                if calendarService.isAuthorized && calendarService.upcomingAdjustments.isEmpty {
                    await calendarService.evaluateSchedule(
                        rules: settings.rules,
                        syncSettings: settings.syncSettings,
                        desiredSleepHours: settings.desiredSleepHours,
                        weeklyDefaults: settings.weeklyDefaults
                    )
                }
            }
        }
    }

    // MARK: - Sub-views

    private var calendarAccessBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Calendar Access Required")
                    .font(.headline)
                Text("Grant access so the app can read your events.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Allow") {
                Task { await calendarService.requestAccess() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .controlSize(.small)
        }
        .padding()
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var noRulesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 44))
                .foregroundStyle(.indigo.opacity(0.5))
            Text("No Rules Configured")
                .font(.headline)
            Text("Go to Settings → Rules to define which calendar events should adjust your sleep schedule.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var allClearView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(.indigo.opacity(0.6))
            Text("You're all set")
                .font(.headline)
            Text("No upcoming events in the next \(settings.syncSettings.lookAheadDays) days affect your sleep schedule.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func lastSyncLabel(_ date: Date) -> some View {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return Text("Last synced \(f.localizedString(for: date, relativeTo: Date()))")
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }
}

// MARK: - Adjustment Card

private struct AdjustmentCardView: View {
    let adjustment: DayAdjustment
    let featured: Bool
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Date header
            HStack {
                Text(adjustment.formattedDate)
                    .font(featured ? .headline : .subheadline)
                    .fontWeight(.semibold)
                Spacer()
                sourceChip
            }

            Divider()

            // Wake / Bedtime
            HStack(spacing: 0) {
                timeStat(icon: "alarm.fill",  label: "Wake",    value: adjustment.formattedWake)
                Spacer()
                Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 1, height: 36)
                Spacer()
                timeStat(icon: "moon.fill",   label: "Bedtime", value: adjustment.formattedBedtime)
            }

            // Trigger info
            if let title = adjustment.triggeringEventTitle {
                Label {
                    Text("Triggered by \"\(title)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Dismiss
            Button(action: onDismiss) {
                Text("Dismiss")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .controlSize(.small)
        }
        .padding()
        .background(
            featured
                ? AnyShapeStyle(.indigo.opacity(0.07))
                : AnyShapeStyle(.regularMaterial),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(featured ? Color.indigo.opacity(0.25) : Color.clear, lineWidth: 1)
        )
    }

    private var sourceChip: some View {
        Text(adjustment.source == .calendarEvent ? "Event" : "Default")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                adjustment.source == .calendarEvent ? Color.indigo.opacity(0.15) : Color.secondary.opacity(0.12),
                in: Capsule()
            )
            .foregroundStyle(adjustment.source == .calendarEvent ? Color.indigo : Color.secondary)
    }

    private func timeStat(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.title3).foregroundStyle(.indigo)
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppSettings())
        .environmentObject(CalendarService())
}
