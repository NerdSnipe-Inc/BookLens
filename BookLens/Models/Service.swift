import Foundation
import SwiftData
import DesignFoundationPro

@Model
final class Service {
    var id: UUID
    var name: String
    var durationMinutes: Int
    var price: Decimal
    var icon: String

    @Relationship(deleteRule: .nullify, inverse: \Appointment.service)
    var appointments: [Appointment] = []

    init(id: UUID = UUID(), name: String, durationMinutes: Int, price: Decimal, icon: String) {
        self.id = id
        self.name = name
        self.durationMinutes = durationMinutes
        self.price = price
        self.icon = icon
    }

    var asDFBookingService: DFBookingService {
        DFBookingService(id: id, name: name, durationMinutes: durationMinutes, price: price, iconSystemName: icon)
    }
}
