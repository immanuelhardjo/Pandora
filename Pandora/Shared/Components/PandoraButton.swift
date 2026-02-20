//
//  PandoraButton.swift
//  Pandora
//
//  Reusable button components following consistent design system
//

import SwiftUI

// MARK: - Button Styles

/// Primary action button with Pandora theme
struct PrimaryButtonStyle: ButtonStyle {
    
    let isDestructive: Bool
    
    init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(isDestructive ? .red : PandoraTheme.Colors.gold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isDestructive
                    ? Color.red.opacity(0.1)
                    : PandoraTheme.Colors.surface
            )
            .cornerRadius(PandoraTheme.Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: PandoraTheme.Layout.cornerRadius)
                    .stroke(
                        isDestructive
                            ? Color.red.opacity(0.5)
                            : PandoraTheme.Colors.gold.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Card-style button with scale animation
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Convenience Button Views

/// Standard Pandora action button
struct PandoraButton: View {
    
    let title: String
    let icon: String?
    let isDestructive: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            if let icon = icon {
                Label(title, systemImage: icon)
            } else {
                Text(title)
            }
        }
        .buttonStyle(PrimaryButtonStyle(isDestructive: isDestructive))
    }
}
