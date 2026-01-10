//
//  RootTabView.swift
//  cashExpense
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                HomeView()
                    .tabItem { Label("Today", systemImage: "house.fill") }
                
                HistoryView()
                    .tabItem { Label("History", systemImage: "list.bullet") }
                
                SummaryView()
                    .tabItem { Label("Summary", systemImage: "chart.bar.fill") }
                
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            
            #if os(iOS)
            // Sticky banner ad at bottom (reserved height ~50)
            AdBannerView()
                .background(Color(.systemBackground))
            #endif
        }
    }
}



