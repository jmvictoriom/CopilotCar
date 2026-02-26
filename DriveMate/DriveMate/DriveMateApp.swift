import SwiftUI

@main
struct DriveMateApp: App {
    static let sharedViewModel = ConversationViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: Self.sharedViewModel)
        }
    }
}
