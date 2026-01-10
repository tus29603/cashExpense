//
//  ActivityShareView.swift
//  cashExpense
//

import SwiftUI

#if os(iOS)
import UIKit

struct ActivityShareView: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#elseif os(macOS)
import AppKit

struct ActivityShareView: NSViewRepresentable {
    let items: [Any]
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.wantsLayer = true
        
        // Show the share picker when view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = view.window, let contentView = window.contentView {
                let picker = NSSharingServicePicker(items: items)
                let rect = NSRect(x: contentView.bounds.midX - 50, y: contentView.bounds.midY - 50, width: 100, height: 100)
                picker.show(relativeTo: rect, of: contentView, preferredEdge: .minY)
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // No-op - sharing is triggered in makeNSView
    }
}
#endif


