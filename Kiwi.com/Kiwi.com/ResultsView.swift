import SwiftUI

struct ResultsView: View {
    let params: SearchParams
    @State private var deals: [FlightDeal] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading…")
            } else if let msg = errorMessage {
                Text("Error: \(msg)")
            } else if deals.isEmpty {
                Text("No deals found")
            } else {
                List(deals) { deal in
                    DealCard(deal: deal)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Results")
        .task {
            await fetchDeals()
        }
    }

    private func fetchDeals() async {
        do {
            isLoading = true
            errorMessage = nil
            let fetched = try await DealsService().loadDeals(params: params)
            deals = fetched
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct DealCard: View {
    let deal: FlightDeal

    private func formatDate(_ unix: TimeInterval) -> String {
        let d = Date(timeIntervalSince1970: unix)
        let f = DateFormatter(); f.dateFormat = "d MMM, HH:mm"
        return f.string(from: d)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(deal.cityFrom) → \(deal.cityTo), \(deal.countryTo.name)")
                    .font(.headline)
                Spacer()
                Text("€\(Int(deal.price))")
                    .font(.headline)
            }
            HStack(spacing: 6) {
                Image(systemName: "airplane.departure")
                Text(formatDate(deal.dTime))
                Spacer()
                Image(systemName: "airplane.arrival")
                Text(formatDate(deal.aTime))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}
