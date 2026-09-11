import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct SchedulingRationale: Sendable {
    @Guide(description: "A short, friendly headline under 8 words announcing the suggested slot")
    var headline: String

    @Guide(description: "One to two sentences explaining why this slot was picked, referencing only the facts given — never invent a different time or a reason not supported by the facts")
    var rationale: String
}

@available(iOS 26.0, macOS 26.0, *)
struct SuggestedSlot {
    let date: Date
    let rationale: SchedulingRationale?
}

/// Suggests the next open appointment slot. The slot itself is always computed
/// deterministically by `SlotFinder` — Foundation Models is only asked to narrate *why* that
/// slot makes sense, never to pick the time itself, so the assistant can never hallucinate an
/// appointment time that doesn't actually exist in the schedule.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
final class SchedulingAssistantEngine {
    private var session: LanguageModelSession?

    var isAvailable: Bool {
        switch SystemLanguageModel.default.availability {
        case .available: return true
        case .unavailable: return false
        }
    }

    func prewarm() {
        guard isAvailable else { return }
        let session = session ?? makeSession()
        self.session = session
        session.prewarm()
    }

    func suggestSlot(
        durationMinutes: Int,
        existing: [Appointment]
    ) async throws -> SuggestedSlot? {
        let existingRanges = existing
            .filter { $0.status == .upcoming }
            .map { (start: $0.date, durationMinutes: $0.service?.durationMinutes ?? 30) }

        guard let slot = SlotFinder.suggestNextSlot(durationMinutes: durationMinutes, existing: existingRanges) else {
            return nil
        }

        guard isAvailable else {
            return SuggestedSlot(date: slot, rationale: nil)
        }

        let session = session ?? makeSession()
        self.session = session

        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short

        let upcomingCount = existingRanges.filter {
            Calendar.current.isDate($0.start, inSameDayAs: slot)
        }.count

        let prompt = """
        The next open appointment slot is \(formatter.string(from: slot)), for a \(durationMinutes)-minute
        service. There are already \(upcomingCount) other appointment(s) booked that same day.
        Business hours are \(SlotFinder.businessStartHour):00 to \(SlotFinder.businessEndHour):00.
        Write a short headline and one-to-two sentence rationale recommending this slot.
        """

        let response = try await session.respond(to: prompt, generating: SchedulingRationale.self)
        return SuggestedSlot(date: slot, rationale: response.content)
    }

    private func makeSession() -> LanguageModelSession {
        LanguageModelSession {
            "You are a friendly, concise scheduling assistant for a small service business. Be specific and only reference the facts you're given — never invent times, dates, or booking counts."
        }
    }
}
#endif
