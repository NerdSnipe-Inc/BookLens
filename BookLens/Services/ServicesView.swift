import SwiftUI
import SwiftData
import DesignFoundation

struct ServicesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Service.name) private var services: [Service]

    @State private var isPresentingAddService = false

    var body: some View {
        NavigationStack {
            Group {
                if services.isEmpty {
                    DFEmptyState(
                        icon: "scissors",
                        title: "No services yet",
                        message: "Add a service with a price and duration so clients can book it.",
                        actionTitle: "Add Service",
                        onAction: { isPresentingAddService = true }
                    )
                } else {
                    DFList(services, onDelete: deleteServices) { service in
                        DFEntityRow(
                            media: .systemImage(service.icon),
                            title: service.name,
                            subtitle: "\(service.durationMinutes) min",
                            trailing: .text(service.price.formatted(.currency(code: "USD")))
                        )
                    }
                }
            }
            .navigationTitle("Services")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddService = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .dfSheet(isPresented: $isPresentingAddService) {
                ServiceFormView()
            }
        }
    }

    private func deleteServices(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(services[index])
        }
    }
}
