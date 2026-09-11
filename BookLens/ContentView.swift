import SwiftUI
import DesignFoundation

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BookingFlowView(selectedTab: $selectedTab)
                .tabItem { Label("Book", systemImage: "calendar.badge.plus") }
                .tag(0)

            MyBookingsView()
                .tabItem { Label("My Bookings", systemImage: "calendar") }
                .tag(1)

            ServicesView()
                .tabItem { Label("Services", systemImage: "scissors") }
                .tag(2)

            SchedulingAssistantView()
                .tabItem { Label("Assistant", systemImage: "sparkles") }
                .tag(3)
        }
    }
}
