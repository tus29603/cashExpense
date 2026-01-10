//
//  CategoryColor.swift
//  cashExpense
//
//  Muted, system-style color palette for category accents
//

import SwiftUI

extension Category {
    /// Returns a muted, system-style color that works in light and dark mode
    /// Used as subtle accent for icon backgrounds
    var accentColor: Color {
        CategoryColor.color(for: colorKey)
    }
}

enum CategoryColor {
    /// Returns a muted, system-style color for the given color key
    /// Colors are intentionally subtle to maintain readability
    static func color(for key: String) -> Color {
        switch key.lowercased() {
        case "red":
            return Color(red: 1.0, green: 0.45, blue: 0.45)
        case "orange":
            return Color(red: 1.0, green: 0.65, blue: 0.3)
        case "yellow":
            return Color(red: 1.0, green: 0.8, blue: 0.3)
        case "green":
            return Color(red: 0.3, green: 0.75, blue: 0.5)
        case "teal":
            return Color(red: 0.3, green: 0.7, blue: 0.75)
        case "blue":
            return Color(red: 0.3, green: 0.6, blue: 1.0)
        case "indigo":
            return Color(red: 0.5, green: 0.55, blue: 0.95)
        case "purple":
            return Color(red: 0.75, green: 0.5, blue: 0.95)
        case "pink":
            return Color(red: 1.0, green: 0.5, blue: 0.75)
        case "brown":
            return Color(red: 0.7, green: 0.55, blue: 0.4)
        case "gray", "grey":
            return Color.secondary
        default:
            return Color.secondary
        }
    }
    
    /// Returns a very subtle, muted background color for icon circles
    /// Uses low opacity to maintain readability
    static func subtleBackground(for key: String) -> Color {
        color(for: key).opacity(0.15)
    }
    
    /// Returns a slightly more visible background for selected states
    static func selectedBackground(for key: String) -> Color {
        color(for: key).opacity(0.25)
    }
}


