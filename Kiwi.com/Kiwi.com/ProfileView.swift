//
//  ProfileView.swift
//  Kiwi.com
//
//  Created by Seyedreza Aghayarikordkandi on 07/11/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44))
                        VStack(alignment: .leading) {
                            Text("Guest user").font(.headline)
                            Text("Sign in to sync your trips").foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Account") {
                    Label("Sign in", systemImage: "person.badge.key")
                    Label("Notifications", systemImage: "bell.badge")
                    Label("Payment methods", systemImage: "creditcard")
                }
                Section("Help") {
                    Label("Support", systemImage: "questionmark.circle")
                    Label("About", systemImage: "info.circle")
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview { ProfileView() }
