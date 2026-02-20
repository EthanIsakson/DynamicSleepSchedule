import SwiftUI

/// Banner shown when a calendar event triggers a suggested sleep adjustment
struct AdjustmentBannerView: View {
    let adjustment: SleepAdjustment
    let onAccept: () -> Void
    let onDismiss: () -> Void

    private var eventDateFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: adjustment.triggeringEventDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Schedule Conflict Detected")
                        .font(.headline)
                    Text(adjustment.triggeringEventTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            // Summary
            Text(adjustment.summaryText)
                .font(.subheadline)
                .foregroundStyle(.primary)

            // Event time
            Label(eventDateFormatted, systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Actions
            HStack(spacing: 10) {
                Button(action: onDismiss) {
                    Text("Dismiss")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)

                Button(action: onAccept) {
                    Text("Apply Change")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
