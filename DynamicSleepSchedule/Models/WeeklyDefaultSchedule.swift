import Foundation

struct DaySchedule: Codable, Equatable {
    var isEnabled: Bool
    var bedtime: Date
    var wakeTime: Date
}

struct WeeklyDefaultSchedule: Codable {

    var sunday: DaySchedule
    var monday: DaySchedule
    var tuesday: DaySchedule
    var wednesday: DaySchedule
    var thursday: DaySchedule
    var friday: DaySchedule
    var saturday: DaySchedule

    // Indexed by Calendar.component(.weekday): 1=Sun … 7=Sat
    subscript(weekday: Int) -> DaySchedule {
        get {
            switch weekday {
            case 1: return sunday
            case 2: return monday
            case 3: return tuesday
            case 4: return wednesday
            case 5: return thursday
            case 6: return friday
            case 7: return saturday
            default: return monday
            }
        }
        set {
            switch weekday {
            case 1: sunday    = newValue
            case 2: monday    = newValue
            case 3: tuesday   = newValue
            case 4: wednesday = newValue
            case 5: thursday  = newValue
            case 6: friday    = newValue
            case 7: saturday  = newValue
            default: break
            }
        }
    }

    static func makeDefault() -> WeeklyDefaultSchedule {
        let cal = Calendar.current
        let ref = Date()
        let weekdayBed  = cal.date(bySettingHour: 22, minute: 30, second: 0, of: ref)!
        let weekdayWake = cal.date(bySettingHour:  6, minute: 30, second: 0, of: ref)!
        let weekendBed  = cal.date(bySettingHour: 23, minute: 30, second: 0, of: ref)!
        let weekendWake = cal.date(bySettingHour:  8, minute:  0, second: 0, of: ref)!

        let weekday = DaySchedule(isEnabled: true, bedtime: weekdayBed,  wakeTime: weekdayWake)
        let weekend = DaySchedule(isEnabled: true, bedtime: weekendBed, wakeTime: weekendWake)

        return WeeklyDefaultSchedule(
            sunday:    weekend,
            monday:    weekday,
            tuesday:   weekday,
            wednesday: weekday,
            thursday:  weekday,
            friday:    weekend,
            saturday:  weekend
        )
    }
}
