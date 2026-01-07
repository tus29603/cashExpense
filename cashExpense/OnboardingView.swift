//
//  OnboardingView.swift
//  cashExpense
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Spacer(minLength: 12)
                
                Text("Track cash spending offline")
                    .font(.largeTitle.weight(.bold))
                
                VStack(alignment: .leading, spacing: 10) {
                    Label("No account, no bank sync", systemImage: "bolt.horizontal.icloud.fill")
                    Label("1‑tap fast entry", systemImage: "hand.tap.fill")
                    Label("Export CSV (Pro)", systemImage: "square.and.arrow.up")
                }
                .font(.headline)
                .padding(.top, 6)
                
                Text("For personal tracking only.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                
                Spacer()
                
                Button {
                    onFinish()
                    dismiss()
                } label: {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Skip") {
                    onFinish()
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 6)
            }
            .padding(.horizontal, 20)
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


