// ============================================================
// Theme.swift
// AC coverage: — (design system infrastructure)
// Depends on: none
// ============================================================

import SwiftUI

// MARK: - Colors

extension Color {
    static let appPrimary  = Color(hex: "#1A73E8")   // Sign In button background
    static let appSurface  = Color(hex: "#FFFFFF")   // Screen background
    static let appError    = Color(hex: "#D93025")   // Error message text
    static let appSubtle   = Color(hex: "#5F6368")   // Placeholder / secondary text
    static let appBorder   = Color(uiColor: .separator)
}

// MARK: - ShapeStyle shorthand (enables `.appPrimary` in foregroundStyle/background)

extension ShapeStyle where Self == Color {
    static var appPrimary: Color { Color(hex: "#1A73E8") }
    static var appSurface: Color { Color(hex: "#FFFFFF") }
    static var appError:   Color { Color(hex: "#D93025") }
    static var appSubtle:  Color { Color(hex: "#5F6368") }
    static var appBorder:  Color { Color(uiColor: .separator) }
}

// MARK: - Hex init (internal to file)

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Typography

extension Font {
    static let appTitle   = Font.system(size: 28, weight: .semibold)
    static let appBody    = Font.system(size: 16, weight: .regular)
    static let appCaption = Font.system(size: 13, weight: .regular)
}

// MARK: - Spacing

enum AppSpacing {
    static let xs: CGFloat          = 4
    static let sm: CGFloat          = 8
    static let md: CGFloat          = 16
    static let lg: CGFloat          = 24
    static let xl: CGFloat          = 32
    static let pagePadding: CGFloat = 24
    static let fieldGap: CGFloat    = 16
    static let sectionGap: CGFloat  = 32
}

// MARK: - Radii

enum AppRadius {
    static let button: CGFloat = 12
    static let field: CGFloat  = 10
    static let card: CGFloat   = 16
}
