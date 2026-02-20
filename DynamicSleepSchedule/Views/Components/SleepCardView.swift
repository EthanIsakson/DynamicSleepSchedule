import SwiftUI

/// Displays a single sleep schedule (bedtime + wake time + duration)
struct SleepCardView: View {
    let title: String
    let schedule: SleepSchedule
    var dimmed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: 0) {
                sleepStat(icon: "moon.fill", label: "Bedtime", value: schedule.formattedBedtime)
                Spacer()
                divider
                Spacer()
                sleepStat(icon: "alarm.fill", label: "Wake", value: schedule.formattedWakeTime)
                Spacer()
                divider
                Spacer()
                sleepStat(icon: "zzz", label: "Duration", value: schedule.formattedDuration)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .opacity(dimmed ? 0.5 : 1)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 1, height: 36)
    }

    private func sleepStat(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.indigo)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let schedule = SleepSchedule(
        bedtime: Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date())!,
        wakeTime: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!
    )
    SleepCardView(title: "Tonight's Schedule", schedule: schedule)
        .padding()
}
