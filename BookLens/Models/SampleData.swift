import Foundation
import SwiftData
import DesignFoundationPro

@MainActor
enum SampleData {
    static func seedIfNeeded(context: ModelContext) {
        let existing = try? context.fetch(FetchDescriptor<Service>())
        guard (existing ?? []).isEmpty else { return }

        let serviceSeeds: [(String, Int, Decimal, String)] = [
            ("Haircut", 30, 35, "scissors"),
            ("Color & Style", 90, 120, "paintbrush"),
            ("Beard Trim", 15, 20, "mustache"),
            ("Deep Conditioning", 45, 55, "drop")
        ]

        var services: [Service] = []
        for (name, duration, price, icon) in serviceSeeds {
            let service = Service(name: name, durationMinutes: duration, price: price, icon: icon)
            context.insert(service)
            services.append(service)
        }

        let calendar = Calendar.current
        let appointmentSeeds: [(String, Int, Int)] = [
            ("Haircut", 2, 10),
            ("Color & Style", -5, 14),
            ("Beard Trim", 6, 9)
        ]
        for (serviceName, daysFromNow, hour) in appointmentSeeds {
            guard let service = services.first(where: { $0.name == serviceName }) else { continue }
            let day = calendar.date(byAdding: .day, value: daysFromNow, to: .now) ?? .now
            let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
            let status: DFBookingStatus = daysFromNow < 0 ? .completed : .upcoming
            context.insert(Appointment(date: date, status: status, service: service))
        }

        try? context.save()
    }
}
