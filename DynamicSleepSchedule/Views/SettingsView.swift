import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var calendarService: CalendarService

    /// Local draft — not written to settings until the user taps Apply.
    @State private var draftFilters: [EventFilter] = []

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

                    ForEach($draftFilters) { $filter in
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

                            Button {
                                draftFilters.removeAll { $0.id == filter.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        draftFilters.append(EventFilter())
                    } label: {
                        Label("Add Filter", systemImage: "plus.circle.fill")
                    }

                    Button {
                        settings.eventFilters = draftFilters
                        Task { await calendarService.sync(settings: settings) }
                    } label: {
                        Label(
                            calendarService.isLoading ? "Syncing…" : "Apply & Sync",
                            systemImage: calendarService.isLoading ? "hourglass" : "arrow.clockwise"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .disabled(calendarService.isLoading)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                } header: {
                    Text("Calendar Sync")
                } footer: {
                    Text(draftFilters.isEmpty
                         ? "All events in the look-ahead window are checked for sleep conflicts."
                         : "Only events that satisfy every filter are checked. Tap Apply & Sync to save and run.")
                }

                // MARK: - About
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
            .animation(.easeInOut(duration: 0.2), value: settings.notificationsEnabled)
            .onAppear {
                draftFilters = settings.eventFilters
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
        .environmentObject(CalendarService())
}
