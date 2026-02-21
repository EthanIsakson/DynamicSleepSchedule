import Foundation

struct EventRule: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var calendarIdentifier: String
    var conditions: [EventCondition]
    var conditionLogic: ConditionLogic
    var wakeOffsetMinutes: Int
    var isEnabled: Bool = true

    func matches(eventTitle: String, location: String?) -> Bool {
        let results = conditions.map { $0.evaluate(title: eventTitle, location: location) }
        switch conditionLogic {
        case .and: return results.allSatisfy { $0 }
        case .or:  return results.contains(true)
        }
    }
}

struct EventCondition: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var field: ConditionField
    var op: ConditionOperator
    var value: String

    func evaluate(title: String, location: String?) -> Bool {
        let target: String
        switch field {
        case .eventName: target = title
        case .location:  target = location ?? ""
        }
        switch op {
        case .equals:      return target.lowercased() == value.lowercased()
        case .contains:    return target.lowercased().contains(value.lowercased())
        case .doesNotEqual: return target.lowercased() != value.lowercased()
        }
    }
}

enum ConditionField: String, Codable, CaseIterable {
    case eventName = "Event Name"
    case location  = "Location"
}

enum ConditionOperator: String, Codable, CaseIterable {
    case equals       = "Equals"
    case contains     = "Contains"
    case doesNotEqual = "Does Not Equal"
}

enum ConditionLogic: String, Codable, CaseIterable {
    case and = "AND"
    case or  = "OR"
}
