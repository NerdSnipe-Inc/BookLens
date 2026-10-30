import SwiftUI
import SwiftData
import DesignFoundation
import DesignFoundationPro

private enum BookingRoute: Hashable {
    case schedule(Service)
    case confirmation(Service, Date, String)

    static func == (lhs: BookingRoute, rhs: BookingRoute) -> Bool {
        switch (lhs, rhs) {
        case let (.schedule(l), .schedule(r)):
            return l.id == r.id
        case let (.confirmation(ls, ld, lt), .confirmation(rs, rd, rt)):
            return ls.id == rs.id && ld == rd && lt == rt
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .schedule(let service):
            hasher.combine(0)
            hasher.combine(service.id)
        case .confirmation(let service, let date, let slot):
            hasher.combine(1)
            hasher.combine(service.id)
            hasher.combine(date)
            hasher.combine(slot)
        }
    }
}

/// The "Book" tab: reuses DesignFoundationPro's `Booking` vertical screens directly
/// (`DFBookingServiceSelectionScreen` → `DFBookingScheduleScreen` → `DFBookingConfirmationScreen`)
/// rather than its convenience `DFBookingRootView`, because we need to hook `onDone` into real
/// SwiftData persistence and an EventKitUI add-to-calendar step the root view has no seam for.
struct BookingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Service.name) private var services: [Service]

    @Binding var selectedTab: Int
    @State private var path = NavigationPath()
    #if os(iOS)
    // "Add to Calendar" is iOS-only: it's built on `EKEventEditViewController` (EventKitUI),
    // which doesn't exist on macOS. See AddToCalendarView.swift for why this isn't ported to
    // macOS's `EKEventStore` permission-based API for this example app.
    @State private var pendingCalendarAdd: (title: String, date: Date, durationMinutes: Int)?
    #endif

    var body: some View {
        NavigationStack(path: $path) {
            DFBookingServiceSelectionScreen(configuration: .init(
                services: services.map(\.asDFBookingService),
                onSelectService: { dfService in
                    guard let service = services.first(where: { $0.id == dfService.id }) else { return }
                    path.append(BookingRoute.schedule(service))
                }
            ))
            .navigationDestination(for: BookingRoute.self, destination: routeDestination)
        }
        #if os(iOS)
        .sheet(item: Binding(
            get: { pendingCalendarAdd.map(CalendarAddItem.init) },
            set: { if $0 == nil { pendingCalendarAdd = nil } }
        )) { item in
            AddToCalendarView(
                title: item.title,
                startDate: item.date,
                durationMinutes: item.durationMinutes,
                onFinish: { pendingCalendarAdd = nil }
            )
        }
        #endif
    }

    @ViewBuilder
    private func routeDestination(_ route: BookingRoute) -> some View {
        switch route {
        case .schedule(let service):
            DFBookingScheduleScreen(configuration: .init(
                service: service.asDFBookingService,
                timeSlots: SlotFinder.dailySlotLabels(),
                onConfirm: { date, slot in path.append(BookingRoute.confirmation(service, date, slot)) }
            ))
        case .confirmation(let service, let day, let slot):
            let appointmentDate = SlotFinder.combine(day: day, slotLabel: slot) ?? day
            DFBookingConfirmationScreen(configuration: .init(
                service: service.asDFBookingService,
                date: day,
                timeSlot: slot,
                onDone: {
                    modelContext.insert(Appointment(date: appointmentDate, service: service))
                    #if os(iOS)
                    pendingCalendarAdd = (title: service.name, date: appointmentDate, durationMinutes: service.durationMinutes)
                    #endif
                    path = NavigationPath()
                    selectedTab = 1
                }
            ))
        }
    }
}

private struct CalendarAddItem: Identifiable {
    let title: String
    let date: Date
    let durationMinutes: Int
    var id: String { "\(title)-\(date.timeIntervalSince1970)" }

    init(_ tuple: (title: String, date: Date, durationMinutes: Int)) {
        self.title = tuple.title
        self.date = tuple.date
        self.durationMinutes = tuple.durationMinutes
    }
}
