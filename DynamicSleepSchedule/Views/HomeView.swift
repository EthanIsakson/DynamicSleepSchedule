import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var calendarService: CalendarService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Calendar permission prompt
                    if !calendarService.isAuthorized {
                        calendarPermissionView
                    }

                    if calendarService.isAuthorized {
                        // First-load spinner
                        if calendarService.isLoading && calendarService.scheduleSummary.isEmpty {
                            ProgressView("Checking calendar…")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)

                        } else if calendarService.scheduleSummary.isEmpty {
                            emptyStateView

                        } else {
                            // Adjusted nights
                            ForEach(calendarService.scheduleSummary) { day in
                                if let adj = day.adjustment {
                                    adjustedDayView(date: day.date, adjustment: adj)
                                }
                            }
                        }

                        // Default schedule — always shown once authorized
                        defaultScheduleView
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

    // MARK: - Adjusted day card

    @ViewBuilder
    private func adjustedDayView(date: Date, adjustment: SleepAdjustment) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header: date + triggering event + shift badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(dateLabel(for: date))
                        .font(.headline)
                    Text(adjustment.triggeringEventTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(abs(adjustment.bedtimeShiftMinutes)) min earlier")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.12), in: Capsule())
            }

            Divider()

            // Adjusted schedule stats
            HStack(spacing: 0) {
                nightStat(icon: "moon.fill",  label: "Bedtime",  value: adjustment.adjusted.formattedBedtime)
                Spacer()
                Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 1, height: 36)
                Spacer()
                nightStat(icon: "alarm.fill", label: "Wake",     value: adjustment.adjusted.formattedWakeTime)
                Spacer()
                Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 1, height: 36)
                Spacer()
                nightStat(icon: "zzz",        label: "Duration", value: adjustment.adjusted.formattedDuration)
            }

            // Event time
            Label(adjustment.triggeringEventDate.formatted(date: .omitted, time: .shortened),
                  systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.orange.opacity(0.25), lineWidth: 1))
    }

    private func nightStat(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Default schedule

    private var defaultScheduleView: some View {
        SleepCardView(
            title: "Default Schedule",
            schedule: SleepSchedule(bedtime: settings.defaultBedtime, wakeTime: settings.defaultWakeTime)
        )
    }

    // MARK: - Empty state

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(.indigo.opacity(0.6))
            Text("No adjusted schedules")
                .font(.headline)
            Text("No events in the next \(settings.eventLookAheadDays) day\(settings.eventLookAheadDays == 1 ? "" : "s") affect your sleep window.")
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
        .padding(.vertical, 32)
    }

    // MARK: - Calendar permission prompt

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

    // MARK: - Helpers

    private func dateLabel(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)    { return "Tonight" }
        if cal.isDateInTomorrow(date) { return "Tomorrow Night" }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}

#Preview {
    HomeView()
        .environmentObject(AppSettings())
        .environmentObject(CalendarService())
}
