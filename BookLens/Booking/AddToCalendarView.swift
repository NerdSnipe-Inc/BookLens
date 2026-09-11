import SwiftUI
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
