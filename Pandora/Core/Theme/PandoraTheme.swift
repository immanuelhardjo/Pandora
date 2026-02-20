//
//  PandoraTheme.swift
//  Pandora
//
//  Created by Immanuel Hardjo on 16/02/26.
//

import SwiftUI

enum PandoraTheme {
    
    // MARK: - Colors
    enum Colors {
        /// The signature Pandora Gold
        static let gold = Color(hex: "#D4AF37")
        
        /// Deepest OLED Black for backgrounds
        static let background = Color.black
        
        /// A subtle charcoal for cards and containers
        static let surface = Color(hex: "#121212")
        
        /// Muted gold for secondary text or borders
        static let goldSecondary = Color(hex: "#AA8A2E")
    }
    
    // MARK: - Gradients
    enum Gradients {
        static let goldLinear = LinearGradient(
            colors: [Colors.gold, Colors.goldSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Layout Constants
    enum Layout {
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 20
        static let iconSize: CGFloat = 60
    }
    
    // MARK: - Shadows
    static func applyGoldGlow(_ view: some View) -> some View {
        view.shadow(color: Colors.gold.opacity(0.4), radius: 15, x: 0, y: 0)
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
