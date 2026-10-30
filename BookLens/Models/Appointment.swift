import Foundation
import SwiftData
import DesignFoundationPro

@Model
final class Appointment {
    var date: Date
    var statusRawValue: String
    var service: Service?
    /// Set once the appointment has been added to the user's Calendar via EventKitUI, so we
    /// don't need to request any calendar read/write access to know it happened.
    var addedToCalendar: Bool

    init(date: Date, status: DFBookingStatus = .upcoming, service: Service?, addedToCalendar: Bool = false) {
        self.date = date
        self.statusRawValue = status.rawValue
        self.service = service
        self.addedToCalendar = addedToCalendar
    }

    var status: DFBookingStatus {
        get { DFBookingStatus(rawValue: statusRawValue) ?? .upcoming }
        set { statusRawValue = newValue.rawValue }
    }

    /// `nil` when the backing `Service` was deleted — such appointments are filtered out of
    /// the Pro vertical's screens, which require a service on every booking.
    var asDFBooking: DFBooking? {
        guard let service else { return nil }
        return DFBooking(service: service.asDFBookingService, date: date, status: status)
    }
}
