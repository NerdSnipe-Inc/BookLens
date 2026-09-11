import Foundation

/// Pure, unit-testable slot-availability logic — no SwiftData/SwiftUI/FoundationModels
/// dependency. The Foundation Models assistant only narrates a slot this type already
/// computed deterministically; it never invents the time itself.
enum SlotFinder {
    static let businessStartHour = 9
    static let businessEndHour = 17
    static let slotGranularityMinutes = 60

    /// Fixed `en_US_POSIX` locale so "h:mm a" round-trips through `dailySlotLabels`/`combine`
    /// reliably regardless of the device's region settings (a device locale without an AM/PM
    /// designator, or a different one, would otherwise make `combine` fail to parse a label
    /// `dailySlotLabels` itself produced). `timeZone` is set per-call to match the `calendar`
    /// argument — otherwise `DateFormatter.date(from:)` interprets "2:30 PM" in the system's
    /// current time zone regardless of which calendar the caller passed in, and reading the
    /// hour back out via that calendar's `dateComponents` silently shifts it by the UTC offset.
    private static func slotLabelFormatter(calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    /// Fixed daily slot labels shown in the booking flow's time picker — the Pro vertical's
    /// `DFBookingScheduleScreen` takes a static list of slot strings, not a per-date query.
    static func dailySlotLabels(calendar: Calendar = .current) -> [String] {
        let formatter = slotLabelFormatter(calendar: calendar)
        let today = calendar.startOfDay(for: .now)
        var labels: [String] = []
        var hour = businessStartHour
        while hour < businessEndHour {
            if let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today) {
                labels.append(formatter.string(from: date))
            }
            hour += slotGranularityMinutes / 60
        }
        return labels
    }

    /// Combines a day (from a date picker) with a slot label (from `dailySlotLabels`) into a
    /// full `Date`.
    static func combine(day: Date, slotLabel: String, calendar: Calendar = .current) -> Date? {
        guard let time = slotLabelFormatter(calendar: calendar).date(from: slotLabel) else { return nil }
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: timeComponents.hour ?? businessStartHour,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: day
        )
    }

    /// The earliest open slot, scanning forward day by day starting from `from`, that doesn't
    /// overlap any `existingStarts` (each paired with its duration in minutes) within business
    /// hours. Returns `nil` if nothing opens up within `maxDaysAhead`.
    static func suggestNextSlot(
        durationMinutes: Int,
        existing: [(start: Date, durationMinutes: Int)],
        from: Date = .now,
        maxDaysAhead: Int = 14,
        calendar: Calendar = .current
    ) -> Date? {
        for dayOffset in 0..<maxDaysAhead {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: from)) else { continue }
            var hour = businessStartHour
            while hour < businessEndHour {
                guard let candidateStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) else {
                    hour += slotGranularityMinutes / 60
                    continue
                }
                let candidateEnd = candidateStart.addingTimeInterval(TimeInterval(durationMinutes * 60))
                let closesInTime = calendar.date(bySettingHour: businessEndHour, minute: 0, second: 0, of: day) ?? day
                let isPast = candidateStart < from
                let fitsBeforeClose = candidateEnd <= closesInTime
                let overlaps = existing.contains { entry in
                    let entryEnd = entry.start.addingTimeInterval(TimeInterval(entry.durationMinutes * 60))
                    return candidateStart < entryEnd && entry.start < candidateEnd
                }
                if !isPast, fitsBeforeClose, !overlaps {
                    return candidateStart
                }
                hour += slotGranularityMinutes / 60
            }
        }
        return nil
    }
}
