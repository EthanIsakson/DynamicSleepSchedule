import SwiftUI

@main
struct DynamicSleepScheduleApp: App {

    @StateObject private var settings = AppSettings()
    @StateObject private var calendarService = CalendarService()
    @StateObject private var focusSleepService = FocusSleepService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(calendarService)
                .environmentObject(focusSleepService)
        }
    }
}
