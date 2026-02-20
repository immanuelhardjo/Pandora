//
//  PandoraCard.swift
//  Pandora
//
//  Reusable card component following Pandora design system
//

import SwiftUI

// MARK: - Card Styles

enum CardStyle {
    case elevated
    case bordered
    case highlighted
    
    var backgroundColor: Color {
        switch self {
        case .elevated, .bordered:
            return PandoraTheme.Colors.surface
        case .highlighted:
            return PandoraTheme.Colors.gold.opacity(0.1)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .elevated:
            return .clear
        case .bordered:
            return PandoraTheme.Colors.gold.opacity(0.3)
        case .highlighted:
            return PandoraTheme.Colors.gold
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .elevated:
            return 8
        case .bordered, .highlighted:
            return 0
        }
    }
}

// MARK: - Pandora Card

/// Reusable card component with consistent styling
struct PandoraCard<Content: View>: View {
    
    let style: CardStyle
    let content: Content
    
    init(
        style: CardStyle = .bordered,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        content
            .background(style.backgroundColor)
            .cornerRadius(PandoraTheme.Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: PandoraTheme.Layout.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style == .highlighted ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.2), radius: style.shadowRadius)
    }
}

// MARK: - Info Card

/// Card for displaying information with icon
struct InfoCard: View {
    
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    let tintColor: Color
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String? = nil,
        tintColor: Color = PandoraTheme.Colors.gold
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.tintColor = tintColor
    }
    
    var body: some View {
        PandoraCard {
            HStack(spacing: 16) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(tintColor)
                        .frame(width: 40, height: 40)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(value)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}
