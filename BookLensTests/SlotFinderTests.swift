import Testing
import Foundation
@testable import BookLens

@Suite("SlotFinder")
struct SlotFinderTests {
    @Test("suggests the business-hours opening slot when nothing is booked")
    func suggestsOpeningSlotWhenFree() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now

        let slot = SlotFinder.suggestNextSlot(durationMinutes: 30, existing: [], from: now, calendar: calendar)

        #expect(slot != nil)
        if let slot {
            #expect(calendar.component(.hour, from: slot) == SlotFinder.businessStartHour)
        }
    }

    @Test("skips a slot that overlaps an existing appointment")
    func skipsOverlappingSlot() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let day = calendar.startOfDay(for: .now)
        let nineAM = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day)!
        let existing = [(start: nineAM, durationMinutes: 60)]

        let slot = SlotFinder.suggestNextSlot(durationMinutes: 60, existing: existing, from: nineAM, calendar: calendar)

        #expect(slot != nil)
        if let slot {
            #expect(calendar.component(.hour, from: slot) == 10)
        }
    }

    @Test("never suggests a slot that ends after business hours close")
    func neverSuggestsPastClose() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let day = calendar.startOfDay(for: .now)
        // Book every hour from 9 to 16 so only a slot on a later day (or none within business
        // hours today) remains — this guards against ever returning e.g. a 16:30 start for a
        // 90-minute service, which would end after the 17:00 close.
        var existing: [(start: Date, durationMinutes: Int)] = []
        for hour in 9..<17 {
            let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
            existing.append((start: start, durationMinutes: 60))
        }

        let slot = SlotFinder.suggestNextSlot(durationMinutes: 90, existing: existing, from: day, calendar: calendar)

        if let slot {
            let end = slot.addingTimeInterval(90 * 60)
            let close = calendar.date(bySettingHour: SlotFinder.businessEndHour, minute: 0, second: 0, of: slot)!
            #expect(end <= close)
        }
    }

    @Test("combine parses a slot label onto the picked day")
    func combineParsesSlotLabel() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let day = calendar.date(from: DateComponents(year: 2026, month: 9, day: 15))!

        let combined = SlotFinder.combine(day: day, slotLabel: "2:30 PM", calendar: calendar)

        #expect(combined != nil)
        if let combined {
            #expect(calendar.component(.hour, from: combined) == 14)
            #expect(calendar.component(.minute, from: combined) == 30)
            #expect(calendar.component(.day, from: combined) == 15)
        }
    }
}
