import SwiftUI

// `EKEventEditViewController` (EventKitUI) is iOS/iPadOS-only UIKit — it has no macOS
// counterpart. On macOS, adding an event without a permission prompt isn't possible the same
// way: there's no "present system UI, zero access" tier, only `EKEventStore.requestFullAccessToEvents`
// plus a real calendar-access grant. Rather than build out full macOS calendar permission
// handling for an example app, BookLens deliberately omits the "Add to Calendar" affordance on
// macOS (see BookingFlowView and the README's Requirements/Screenshots sections) and this file
// compiles only on iOS.
#if os(iOS)
import EventKit
import EventKitUI

/// Wraps `EKEventEditViewController` — Tier 1 EventKit access (no permission prompt, no
/// Info.plist key, runs out-of-process on iOS 17+). This is the *only* correct way to add a
/// single event to a user's calendar without asking for broad calendar access first.
struct AddToCalendarView: UIViewControllerRepresentable {
    let title: String
    let startDate: Date
    let durationMinutes: Int
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))

        let controller = EKEventEditViewController()
        controller.event = event
        controller.eventStore = store
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            controller.dismiss(animated: true)
            onFinish()
        }
    }
}
#endif
