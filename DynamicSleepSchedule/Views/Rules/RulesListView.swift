import SwiftUI

struct RulesListView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var calendarService: CalendarService
    @State private var showingEditor = false
    @State private var editingRule: EventRule?

    var body: some View {
        List {
            if settings.rules.isEmpty {
                emptyState
            } else {
                ForEach($settings.rules) { $rule in
                    RuleRowView(rule: $rule)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingRule = rule
                            showingEditor = true
                        }
                }
                .onDelete(perform: deleteRules)
            }
        }
        .navigationTitle("Rules")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingRule = nil
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            if !settings.rules.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            RuleEditorView(existingRule: editingRule) { saved in
                if let idx = settings.rules.firstIndex(where: { $0.id == saved.id }) {
                    settings.rules[idx] = saved
                } else {
                    settings.rules.append(saved)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 44))
                .foregroundStyle(.indigo.opacity(0.5))
            Text("No Rules Yet")
                .font(.headline)
            Text("Tap + to create a rule. Rules define which calendar events adjust your sleep schedule.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func deleteRules(at offsets: IndexSet) {
        settings.rules.remove(atOffsets: offsets)
    }
}

// MARK: - Rule Row

private struct RuleRowView: View {
    @Binding var rule: EventRule

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.title2)
                .foregroundStyle(rule.isEnabled ? .indigo : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(rule.name.isEmpty ? "Unnamed Rule" : rule.name)
                    .font(.headline)
                    .foregroundStyle(rule.isEnabled ? .primary : .secondary)
                Text(conditionSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: $rule.isEnabled)
                .labelsHidden()
                .tint(.indigo)
        }
        .padding(.vertical, 4)
    }

    private var conditionSummary: String {
        let parts = rule.conditions.map { "\($0.field.rawValue) \($0.op.rawValue) \"\($0.value)\"" }
        if parts.isEmpty { return "No conditions" }
        let joiner = " \(rule.conditionLogic.rawValue) "
        return parts.joined(separator: joiner) + " · \(rule.wakeOffsetMinutes) min offset"
    }
}

#Preview {
    NavigationStack {
        RulesListView()
            .environmentObject(AppSettings())
            .environmentObject(CalendarService())
    }
}
