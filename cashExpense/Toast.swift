//
//  Toast.swift
//  cashExpense
//

import SwiftUI
import Combine

@MainActor
final class ToastManager: ObservableObject {
    @Published var message: String?
    
    func show(_ message: String, duration: Duration = .seconds(1.2)) {
        self.message = message
        Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.message = nil
        }
    }
}

struct ToastModifier: ViewModifier {
    let message: String?
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message {
                    Text(message)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .accessibilityLabel(message)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: message)
    }
}

extension View {
    func toast(message: String?) -> some View {
        modifier(ToastModifier(message: message))
    }
}


