//
//  ReviewManager.swift
//  cashExpense
//
//  Manages App Store review prompting using SKStoreReviewController
//

import SwiftUI
import StoreKit
import Combine

@MainActor
final class ReviewManager: ObservableObject {
    @Published var showingReviewPrompt = false
    
    private let expenseCountKey = "reviewExpenseCount"
    private let hasRequestedReviewKey = "hasRequestedReview"
    private let reviewThreshold = 10
    
    private var expenseCount: Int {
        get { UserDefaults.standard.integer(forKey: expenseCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: expenseCountKey) }
    }
    
    private var hasRequestedReview: Bool {
        get { UserDefaults.standard.bool(forKey: hasRequestedReviewKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasRequestedReviewKey) }
    }
    
    func recordExpenseAdded() {
        guard !hasRequestedReview else { return }
        
        expenseCount += 1
        
        if expenseCount >= reviewThreshold {
            showingReviewPrompt = true
        }
    }
    
    func requestReview() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        SKStoreReviewController.requestReview(in: windowScene)
        hasRequestedReview = true
        showingReviewPrompt = false
    }
    
    func dismissReviewPrompt() {
        showingReviewPrompt = false
    }
}

struct ReviewPromptView: View {
    @ObservedObject var reviewManager: ReviewManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("If this app has been helpful, would you mind rating it? It really helps.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Button {
                        reviewManager.requestReview()
                        dismiss()
                    } label: {
                        Text("Rate Now")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        reviewManager.dismissReviewPrompt()
                        dismiss()
                    } label: {
                        Text("Not Now")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
            .navigationTitle("Rate App")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .interactiveDismissDisabled()
        }
        .presentationDetents([.height(220)])
    }
}
