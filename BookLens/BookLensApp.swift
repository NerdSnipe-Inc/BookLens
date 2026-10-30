import SwiftUI
import SwiftData
import DesignFoundation

@main
struct BookLensApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Service.self, Appointment.self)
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }

        SampleData.seedIfNeeded(context: modelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .dfThemePreset(.copper)
        }
        .modelContainer(modelContainer)
    }
}
