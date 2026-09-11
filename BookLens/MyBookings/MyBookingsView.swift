import SwiftUI
import SwiftData
import DesignFoundation
import DesignFoundationPro

struct MyBookingsView: View {
    @Query(sort: \Appointment.date) private var appointments: [Appointment]
    @State private var selectedDate = Date.now
    @Environment(\.dfTheme) private var theme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DFCalendarView(selection: $selectedDate) { date in
                    if hasAppointment(on: date) {
                        Circle()
                            .fill(theme.colors.primary)
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                DFMyBookingsScreen(configuration: .init(bookings: bookings))
            }
        }
    }

    private var bookings: [DFBooking] {
        appointments.compactMap(\.asDFBooking)
    }

    private func hasAppointment(on date: Date) -> Bool {
        let calendar = Calendar.current
        return appointments.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
}
