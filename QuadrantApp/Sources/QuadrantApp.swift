import SwiftUI

@main
struct QuadrantApp: App {
    @StateObject private var store = TaskStore()
    @StateObject private var pomodoro = PomodoroTimer()

    var body: some Scene {
        Window("Q Box", id: "main") {
            ContentView()
                .environmentObject(store)
                .environmentObject(pomodoro)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 860, height: 640)

        MenuBarExtra {
            MenuBarView()
                .environmentObject(store)
                .environmentObject(pomodoro)
        } label: {
            Image(systemName: "square.grid.2x2.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
