import SwiftUI
import SwiftData
import DesignFoundation

struct SchedulingAssistantView: View {
    @Query private var appointments: [Appointment]
    @Query(sort: \Service.name) private var services: [Service]

    var body: some View {
        NavigationStack {
            Group {
                #if canImport(FoundationModels)
                if #available(iOS 26.0, macOS 26.0, *) {
                    AssistantContent(appointments: appointments, defaultDuration: services.first?.durationMinutes ?? 30)
                } else {
                    unavailableState
                }
                #else
                unavailableState
                #endif
            }
            .navigationTitle("AI Assistant")
        }
    }

    private var unavailableState: some View {
        DFEmptyState(
            icon: "sparkles",
            title: "Requires Apple Intelligence",
            message: "The scheduling assistant needs iOS 26 (or macOS 26) with Apple Intelligence enabled. The next open slot is still found deterministically — only the write-up needs it."
        )
    }
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
private struct AssistantContent: View {
    let appointments: [Appointment]
    let defaultDuration: Int

    @State private var engine = SchedulingAssistantEngine()
    @State private var suggestion: SuggestedSlot?
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !engine.isAvailable {
                    DFEmptyState(
                        icon: "sparkles",
                        title: "Apple Intelligence unavailable",
                        message: "Turn on Apple Intelligence in Settings to generate a write-up on this device."
                    )
                } else if isGenerating {
                    DFSkeleton(shape: .roundedRectangle(cornerRadius: 8)).frame(height: 20)
                    DFSkeleton(shape: .roundedRectangle(cornerRadius: 8)).frame(height: 60)
                } else if let suggestion {
                    DFCard {
                        VStack(alignment: .leading, spacing: 8) {
                            if let rationale = suggestion.rationale {
                                DFText(rationale.headline, scale: .headline)
                                DFText(rationale.rationale, scale: .body)
                                Divider()
                            }
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                DFText(suggestion.date.formatted(date: .abbreviated, time: .shortened), scale: .caption)
                            }
                        }
                        .padding()
                    }
                    DFButton("Regenerate", style: .outlined) {
                        Task { await generate() }
                    }
                } else if let errorMessage {
                    DFEmptyState(icon: "exclamationmark.triangle", title: "Couldn't find a suggestion", message: errorMessage)
                } else {
                    DFEmptyState(icon: "calendar", title: "Fully booked", message: "No open slot found in the next two weeks.")
                }
            }
            .padding()
        }
        .task {
            engine.prewarm()
            await generate()
        }
    }

    private func generate() async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }
        do {
            suggestion = try await engine.suggestSlot(durationMinutes: defaultDuration, existing: appointments)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif
