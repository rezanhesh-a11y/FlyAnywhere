//
//  TripsView.swift
//  Kiwi.com
//
//  Created by Seyedreza Aghayarikordkandi on 07/11/25.
//

import SwiftUI

struct TripsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "suitcase.fill")
                    .font(.system(size: 42))
                Text("No trips yet")
                    .font(.headline)
                Text("When you book, your trips will appear here.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("My Trips")
        }
    }
}

#Preview { TripsView() }
