import SwiftUI

@main
struct DynamicSleepScheduleApp: App {

    @StateObject private var settings       = AppSettings()
    @StateObject private var calendarService = CalendarService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(calendarService)
        }
    }
}
