import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var calendarService: CalendarService

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Rules & Schedules
                Section("Calendar Rules") {
                    NavigationLink {
                        RulesListView()
                            .environmentObject(settings)
                            .environmentObject(calendarService)
                    } label: {
                        Label {
                            HStack {
                                Text("Rules")
                                Spacer()
                                Text(settings.rules.isEmpty ? "None" : "\(settings.rules.count)")
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "list.bullet.clipboard")
                        }
                    }

                    NavigationLink {
                        DefaultScheduleView()
                            .environmentObject(settings)
                    } label: {
                        Label("Default Schedule", systemImage: "calendar")
                    }
                }

                // MARK: - Sleep Goal
                Section {
                    Stepper(value: $settings.desiredSleepHours, in: 5...12, step: 0.5) {
                        HStack {
                            Text("Desired Sleep")
                            Spacer()
                            Text(String(format: "%.1f hrs", settings.desiredSleepHours))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Sleep Goal")
                } footer: {
                    Text("Bedtime is calculated as wake time minus your desired sleep duration.")
                }

                // MARK: - Sync
                Section {
                    Stepper(value: $settings.syncSettings.lookAheadDays, in: 1...30) {
                        HStack {
                            Text("Look Ahead")
                            Spacer()
                            Text("\(settings.syncSettings.lookAheadDays) days")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker("Frequency", selection: $settings.syncSettings.frequency) {
                        ForEach(SyncFrequency.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }

                    DatePicker("First Run At",
                               selection: $settings.syncSettings.syncTime,
                               displayedComponents: .hourAndMinute)
                } header: {
                    Text("Sync Schedule")
                } footer: {
                    Text("The app scans your calendar on this schedule and updates sleep suggestions automatically.")
                }

                // MARK: - Notifications
                Section {
                    Toggle(isOn: $settings.notificationsEnabled) {
                        Label("Enable Notifications", systemImage: "bell.fill")
                    }
                    .tint(.indigo)

                    if settings.notificationsEnabled {
                        Toggle(isOn: $settings.showChangeSummary) {
                            Label("Show Change Summary", systemImage: "text.alignleft")
                        }
                        .tint(.indigo)
                        .transition(.move(edge: .top).combined(with: .opacity))

                        Stepper(value: $settings.notifyHoursBeforeBedtime, in: 1...6) {
                            Label {
                                Text("Notify \(settings.notifyHoursBeforeBedtime)h before bedtime")
                            } icon: {
                                Image(systemName: "clock")
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if settings.notificationsEnabled {
                        Text(settings.showChangeSummary
                             ? "You'll receive a notification with a summary of each schedule change."
                             : "You'll receive a simple notification when your schedule changes.")
                    } else {
                        Text("Turn on notifications to be alerted when a calendar event affects your sleep schedule.")
                    }
                }

                // MARK: - About
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
            .animation(.easeInOut(duration: 0.2), value: settings.notificationsEnabled)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
        .environmentObject(CalendarService())
}
