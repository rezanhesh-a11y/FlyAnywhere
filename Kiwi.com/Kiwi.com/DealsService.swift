//
//  DealsService.swift
//  Kiwi.com
//
//  Created by Seyedreza Aghayarikordkandi on 10/11/25.
//
import Foundation

struct SearchParams {
    let from: String
    let to: String
    let tripType: TripType
    let flexibleDates: Bool
    let departDate: Date
    let returnDate: Date
    let selectedMonths: [Date]
    let minNights: Int
    let maxNights: Int
    let passengers: Int
}

struct FlightDeal: Identifiable, Decodable {
    var id: String { "\(cityFrom)-\(cityTo)-\(dTime)" }
    let cityFrom: String
    let cityTo: String
    let countryTo: Country
    let price: Double
    let dTime: TimeInterval
    let aTime: TimeInterval
    let airlines: [String]
    let deep_link: String?

    struct Country: Decodable {
        let name: String
    }
}

struct SearchResponse: Decodable {
    let data: [FlightDeal]
    let currency: String?
}

final class DealsService {
    private let client = TequilaClient()

    func loadDeals(params: SearchParams) async throws -> [FlightDeal] {
        let df = DateFormatter(); df.dateFormat = "dd/MM/yyyy"
        var query: [String: String] = [
            "curr": "EUR",
            "adults": "\(params.passengers)",
            "sort": "price",
            "limit": "30",
            "vehicle_type": "aircraft"
        ]

        if params.tripType == .oneWay {
            query["flight_type"] = "oneway"
        } else {
            query["flight_type"] = "round"
        }

        // مبدا / مقصد
        if !params.from.isEmpty {
            query["fly_from"] = params.from
        }
        if !params.to.isEmpty {
            query["fly_to"] = params.to
        }

        if params.flexibleDates {
            // flexible
            let cal = Calendar.current
            let months = params.selectedMonths
            let start = months.first ?? params.departDate
            let endMonth = months.last ?? start
            let startDate = cal.date(from: cal.dateComponents([.year, .month], from: start))!
            let endDate = cal.date(byAdding: DateComponents(month: 1, day: -1),
                                   to: cal.date(from: cal.dateComponents([.year, .month], from: endMonth))!)!
            query["date_from"] = df.string(from: startDate)
            query["date_to"]   = df.string(from: endDate)

            if params.tripType == .returnTrip {
                query["nights_in_dst_from"] = "\(params.minNights)"
                query["nights_in_dst_to"]   = "\(params.maxNights)"
            }
        } else {
            // دقیق
            query["date_from"] = df.string(from: params.departDate)
            query["date_to"]   = df.string(from: params.departDate)
            if params.tripType == .returnTrip {
                let back = max(params.returnDate, params.departDate)
                query["return_from"] = df.string(from: back)
                query["return_to"]   = df.string(from: back)
            }
        }

        let data = try await client.get(path: "/v2/search", query: query)
        let result = try JSONDecoder().decode(SearchResponse.self, from: data)
        return result.data
    }
}
