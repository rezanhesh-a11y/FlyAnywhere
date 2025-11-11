//
//  RootTabView.swift
//  Kiwi.com
//
//  Created by Seyedreza Aghayarikordkandi on 07/11/25.
//
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            // 1) Search
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass.circle.fill")
                    Text("Search")
                }
                .accessibilityLabel("Search")

            // 2) My Trips
            TripsView()
                .tabItem {
                    Image(systemName: "suitcase.fill")
                    Text("My Trips")
                }
                .accessibilityLabel("My Trips")

            // 3) Profile
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profile")
                }
                .accessibilityLabel("Profile")
        }
        // iOS 16+ adaptive style
        .tint(.green) // رنگ اصلی برند Kiwi
    }
}

#Preview {
    RootTabView()
}
