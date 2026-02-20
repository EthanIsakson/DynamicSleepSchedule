import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NavigationStack {
            Form {

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

                // MARK: - Default Sleep Window
                Section {
                    DatePicker(
                        "Bedtime",
                        selection: $settings.defaultBedtime,
                        displayedComponents: .hourAndMinute
                    )
                    DatePicker(
                        "Wake Time",
                        selection: $settings.defaultWakeTime,
                        displayedComponents: .hourAndMinute
                    )
                    Stepper(value: $settings.minimumSleepHours, in: 5...10, step: 0.5) {
                        HStack {
                            Text("Minimum Sleep")
                            Spacer()
                            Text(String(format: "%.1f hrs", settings.minimumSleepHours))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Default Sleep Window")
                } footer: {
                    Text("The app will never suggest a schedule that dips below your minimum sleep target.")
                }

                // MARK: - About
                Section("About") {
                    LabeledContent("Version", value: "1.0 (Phase 1)")
                    LabeledContent("Calendar Sync", value: "Coming in Phase 2")
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
}
