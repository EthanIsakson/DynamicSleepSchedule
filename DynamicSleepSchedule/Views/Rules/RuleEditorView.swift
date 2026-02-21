import SwiftUI
import EventKit

struct RuleEditorView: View {
    @EnvironmentObject private var calendarService: CalendarService
    @Environment(\.dismiss) private var dismiss

    let onSave: (EventRule) -> Void

    @State private var rule: EventRule

    init(existingRule: EventRule?, onSave: @escaping (EventRule) -> Void) {
        self.onSave = onSave
        _rule = State(initialValue: existingRule ?? EventRule(
            name: "",
            calendarIdentifier: "",
            conditions: [EventCondition(field: .eventName, op: .contains, value: "")],
            conditionLogic: .and,
            wakeOffsetMinutes: 60
        ))
    }

    private var isEditing: Bool { !rule.calendarIdentifier.isEmpty }
    private var canSave: Bool {
        !rule.name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !rule.calendarIdentifier.isEmpty &&
        rule.conditions.allSatisfy { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Name
                Section("Rule Name") {
                    TextField("e.g. Work Shifts", text: $rule.name)
                }

                // MARK: Calendar
                Section("Calendar") {
                    if calendarService.isAuthorized {
                        Picker("Calendar", selection: $rule.calendarIdentifier) {
                            Text("Select a calendar…").tag("")
                            ForEach(calendarService.availableCalendars, id: \.calendarIdentifier) { cal in
                                Text(cal.title).tag(cal.calendarIdentifier)
                            }
                        }
                    } else {
                        Button {
                            Task { await calendarService.requestAccess() }
                        } label: {
                            Label("Grant Calendar Access", systemImage: "lock.open")
                        }
                        .foregroundStyle(.indigo)
                    }
                }

                // MARK: Conditions
                Section {
                    ForEach($rule.conditions) { $condition in
                        ConditionRowView(condition: $condition)
                    }
                    .onDelete { rule.conditions.remove(atOffsets: $0) }

                    Button {
                        rule.conditions.append(EventCondition(field: .eventName, op: .contains, value: ""))
                    } label: {
                        Label("Add Condition", systemImage: "plus.circle")
                    }
                    .foregroundStyle(.indigo)
                } header: {
                    Text("Conditions")
                } footer: {
                    if rule.conditions.count > 1 {
                        Text("Events must match \(rule.conditionLogic == .and ? "ALL" : "ANY") of the conditions above.")
                    }
                }

                // MARK: Condition Logic (only when multiple conditions)
                if rule.conditions.count > 1 {
                    Section("Condition Logic") {
                        Picker("Logic", selection: $rule.conditionLogic) {
                            ForEach(ConditionLogic.allCases, id: \.self) { logic in
                                Text(logic.rawValue).tag(logic)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // MARK: Wake Offset
                Section {
                    Stepper(value: $rule.wakeOffsetMinutes, in: 15...240, step: 15) {
                        HStack {
                            Text("Wake Offset")
                            Spacer()
                            Text(formattedOffset)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Wake this many minutes before the matching event starts.")
                }
            }
            .navigationTitle(isEditing ? "Edit Rule" : "New Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(rule)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }

    private var formattedOffset: String {
        let h = rule.wakeOffsetMinutes / 60
        let m = rule.wakeOffsetMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0           { return "\(h)h" }
        return "\(m)m"
    }
}

// MARK: - Condition Row

private struct ConditionRowView: View {
    @Binding var condition: EventCondition

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Picker("Field", selection: $condition.field) {
                    ForEach(ConditionField.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Picker("Operator", selection: $condition.op) {
                    ForEach(ConditionOperator.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            TextField("Value", text: $condition.value)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    RuleEditorView(existingRule: nil) { _ in }
        .environmentObject(CalendarService())
}
