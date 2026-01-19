//
//  RootView.swift
//  cashExpense
//
//  Clean root view with full-screen layout
//

import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                TodayView()
                    .tabItem { Label("Today", systemImage: "house.fill") }
                
                HistoryView()
                    .tabItem { Label("History", systemImage: "list.bullet") }
                
                SummaryView()
                    .tabItem { Label("Summary", systemImage: "chart.bar.fill") }
                
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            
            #if os(iOS)
            AdBannerView()
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
            #endif
        }
    }
}
