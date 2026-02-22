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

                // MARK: - Calendar Sync
                Section {
                    Stepper(value: $settings.eventLookAheadDays, in: 1...30) {
                        HStack {
                            Text("Look Ahead")
                            Spacer()
                            Text("\(settings.eventLookAheadDays) day\(settings.eventLookAheadDays == 1 ? "" : "s")")
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach($settings.eventFilters) { $filter in
                        HStack(spacing: 8) {
                            Picker("", selection: $filter.op) {
                                ForEach(EventFilter.Operator.allCases, id: \.self) { op in
                                    Text(op.rawValue).tag(op)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()

                            TextField("event name", text: $filter.value)
                        }
                    }
                    .onDelete { settings.eventFilters.remove(atOffsets: $0) }

                    Button {
                        settings.eventFilters.append(EventFilter())
                    } label: {
                        Label("Add Filter", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Calendar Sync")
                } footer: {
                    Text(settings.eventFilters.isEmpty
                         ? "All events in the look-ahead window are checked for sleep conflicts."
                         : "Only events that satisfy every filter are checked for conflicts. Swipe a filter left to delete it.")
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
}
