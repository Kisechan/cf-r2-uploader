import SwiftUI

@main
struct CFR2UploaderApp: App {
    @StateObject private var menuBarViewModel = MenuBarViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()

    var body: some Scene {
        MenuBarExtra("CFR2Uploader", systemImage: menuBarViewModel.statusIconName) {
            MenuBarContentView(
                viewModel: menuBarViewModel,
                openSettings: { settingsViewModel.reload() }
            )
        }
        .menuBarExtraStyle(.window)
        .onChange(of: scenePhase) {
            menuBarViewModel.refreshClipboardAvailability()
        }

        Settings {
            SettingsView(
                viewModel: settingsViewModel,
                didSave: {
                    Task {
                        await menuBarViewModel.reload()
                    }
                }
            )
            .frame(width: 520, height: 380)
        }
    }

    @Environment(\.scenePhase) private var scenePhase
}
