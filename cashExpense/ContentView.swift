//
//  ContentView.swift
//  cashExpense
//
//  Created by Tesfaldet Haileab on 1/7/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var toastManager: ToastManager
    @EnvironmentObject private var lockManager: LockManager
    @Environment(\.scenePhase) private var scenePhase
    
    @Query(sort: \AppConfig.createdAt, order: .forward) private var configs: [AppConfig]
    @Query(sort: \Category.sortOrder, order: .forward) private var categories: [Category]
    @Query(sort: \Expense.createdAt, order: .reverse) private var expenses: [Expense]
    
    private var config: AppConfig? { configs.first }

    var body: some View {
        RootTabView()
            .onAppear {
                SeedData.ensureSeeded(modelContext: modelContext)
                lockManager.syncConfig(config)
            }
            .onChange(of: config?.hasPro) { _, _ in
                lockManager.syncConfig(config)
            }
            .onChange(of: config?.isAppLockEnabled) { _, _ in
                lockManager.syncConfig(config)
            }
            .onChange(of: scenePhase) { _, newValue in
                lockManager.handleScenePhaseChange(newValue)
            }
            .sheet(isPresented: Binding(get: {
                guard let config else { return false }
                return !config.hasSeenOnboarding
            }, set: { _ in })) {
                OnboardingView(onFinish: {
                    guard let config else { return }
                    config.hasSeenOnboarding = true
                    config.updatedAt = Date()
                })
            }
            .overlay {
                if lockManager.shouldShowLockOverlay(config: config) {
                    LockOverlayView(lockManager: lockManager)
                }
            }
            .toast(message: toastManager.message)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, Category.self, AppConfig.self], inMemory: true)
}
