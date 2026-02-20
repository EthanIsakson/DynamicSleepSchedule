import SwiftUI

@main
struct DynamicSleepScheduleApp: App {

    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
