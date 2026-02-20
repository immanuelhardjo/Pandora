//
//  HubCard.swift
//  Pandora
//
//  Created by Immanuel Hardjo on 16/02/26.
//  Enhanced with improved design and accessibility
//

import SwiftUI

// MARK: - Hub Card

/// Card component representing a MicroApp in the Hub
/// Follows component-based design with proper separation of concerns
struct HubCard: View {
    
    // MARK: - Properties
    
    let app: AnyMicroApp
    let action: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                iconView
                titleView
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(PandoraTheme.Colors.surface)
            .cornerRadius(PandoraTheme.Layout.cornerRadius)
            .overlay(borderOverlay)
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityLabel("Open \(app.metadata.name)")
        .accessibilityHint("Double tap to launch \(app.metadata.name) micro app")
    }
    
    // MARK: - Subviews
    
    private var iconView: some View {
        Image(systemName: app.metadata.iconName)
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(PandoraTheme.Colors.gold)
            .accessibilityHidden(true)
    }
    
    private var titleView: some View {
        VStack(spacing: 4) {
            Text(app.metadata.name)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            if !app.metadata.description.isEmpty {
                Text(app.metadata.description)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
            }
        }
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: PandoraTheme.Layout.cornerRadius)
            .stroke(PandoraTheme.Colors.gold.opacity(0.3), lineWidth: 1)
    }
}

