import SwiftUI

struct DefaultScheduleView: View {
    @EnvironmentObject private var settings: AppSettings

    // Weekday index 1=Sun … 7=Sat, display order Mon–Sun
    private let orderedWeekdays: [(name: String, index: Int)] = [
        ("Monday", 2), ("Tuesday", 3), ("Wednesday", 4),
        ("Thursday", 5), ("Friday", 6), ("Saturday", 7), ("Sunday", 1)
    ]

    var body: some View {
        List {
            Section {
                ForEach(orderedWeekdays, id: \.index) { day in
                    DayScheduleRowView(
                        dayName: day.name,
                        schedule: scheduleBinding(for: day.index)
                    )
                }
            } footer: {
                Text("When no calendar event matches on a given day, the app falls back to that day's default. Disable a day to skip it entirely.")
            }
        }
        .navigationTitle("Default Schedule")
        .navigationBarTitleDisplayMode(.large)
    }

    private func scheduleBinding(for weekday: Int) -> Binding<DaySchedule> {
        Binding(
            get: { settings.weeklyDefaults[weekday] },
            set: { settings.weeklyDefaults[weekday] = $0 }
        )
    }
}

// MARK: - Day Row

private struct DayScheduleRowView: View {
    let dayName: String
    @Binding var schedule: DaySchedule

    var body: some View {
        VStack(spacing: 0) {
            // Header row: day name + enable toggle
            HStack {
                Text(dayName)
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $schedule.isEnabled)
                    .labelsHidden()
                    .tint(.indigo)
            }
            .padding(.vertical, 8)

            if schedule.isEnabled {
                Divider()

                HStack(spacing: 0) {
                    timeField(label: "Bedtime", icon: "moon.fill", binding: $schedule.bedtime)
                    Divider().frame(height: 44)
                    timeField(label: "Wake", icon: "alarm.fill", binding: $schedule.wakeTime)
                }
                .padding(.vertical, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: schedule.isEnabled)
    }

    private func timeField(label: String, icon: String, binding: Binding<Date>) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.indigo)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            DatePicker("", selection: binding, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        DefaultScheduleView()
            .environmentObject(AppSettings())
    }
}
