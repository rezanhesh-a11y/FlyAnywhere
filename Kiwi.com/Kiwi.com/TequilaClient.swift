//
//  TequilaClient.swift
//  Kiwi.com
//
//  Created by Seyedreza Aghayarikordkandi on 10/11/25.
//

import Foundation

struct TequilaClient {
    private let apiKey = "YOUR_TEQUILA_API_KEY_HERE"  // 🔑 این را با کلید خودت جایگزین کن
    private let baseURL = URL(string: "https://tequila-api.kiwi.com")!
    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        cfg.httpAdditionalHeaders = ["accept": "application/json"]
        return URLSession(configuration: cfg)
    }()

    func get(path: String, query: [String: String]) async throws -> Data {
        var comps = URLComponents(url: baseURL.appendingPathComponent(path),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
