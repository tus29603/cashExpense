//
//  cashExpenseApp.swift
//  cashExpense
//
//  Created by Tesfaldet Haileab on 1/7/26.
//

import SwiftUI
import SwiftData

// TEMPORARY: Comment out until GoogleMobileAds package is added
// #if os(iOS)
// import GoogleMobileAds
// #endif

@main
struct cashExpenseApp: App {
    @StateObject private var toastManager = ToastManager()
    @StateObject private var lockManager = LockManager()
    
    init() {
        #if os(iOS)
        // Verify App ID exists in Info.plist
        if let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String {
            print("✅ AdMob App ID found: \(appID)")
            
            // UNCOMMENT AFTER ADDING GOOGLE MOBILE ADS PACKAGE:
            // GADMobileAds.sharedInstance().start(completionHandler: nil)
        } else {
            print("⚠️ WARNING: GADApplicationIdentifier not found in Info.plist! Add it to target's Info.plist settings.")
        }
        #endif
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
            Category.self,
            AppConfig.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(toastManager)
                .environmentObject(lockManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
