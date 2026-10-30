import SwiftUI
import DesignFoundation

struct ServiceFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var durationText = "30"
    @State private var priceText = ""
    @State private var icon = "scissors"

    private let iconChoices = [
        "scissors", "paintbrush", "mustache", "drop", "sparkles",
        "hand.raised", "figure.arms.open", "wand.and.stars", "calendar", "star.fill"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DFTextField("Name", text: $name, placeholder: "Haircut")
                    DFTextField("Duration (minutes)", text: $durationText, placeholder: "30")
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    DFTextField("Price", text: $priceText, placeholder: "35.00")
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif

                    Text("Icon")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(iconChoices, id: \.self) { candidate in
                            Button {
                                icon = candidate
                            } label: {
                                Image(systemName: candidate)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(icon == candidate ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Add Service")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    DFButton("Cancel", style: .ghost) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    DFButton("Save") { save() }
                        .disabled(name.isEmpty || Int(durationText) == nil || Decimal(string: priceText) == nil)
                }
            }
        }
    }

    private func save() {
        guard let duration = Int(durationText), let price = Decimal(string: priceText) else { return }
        let service = Service(name: name, durationMinutes: duration, price: price, icon: icon)
        modelContext.insert(service)
        dismiss()
    }
}
