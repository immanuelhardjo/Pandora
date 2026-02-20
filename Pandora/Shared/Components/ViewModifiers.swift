//
//  ViewModifiers.swift
//  Pandora
//
//  Custom view modifiers for consistent styling
//

import SwiftUI

// MARK: - Gold Glow Modifier

struct GoldGlowModifier: ViewModifier {
    
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: PandoraTheme.Colors.gold.opacity(intensity),
                radius: 15,
                x: 0,
                y: 0
            )
    }
}

extension View {
    func goldGlow(intensity: CGFloat = 0.4) -> some View {
        modifier(GoldGlowModifier(intensity: intensity))
    }
}

// MARK: - Pandora Background

struct PandoraBackgroundModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        ZStack {
            PandoraTheme.Colors.background
                .ignoresSafeArea()
            
            content
        }
    }
}

extension View {
    func pandoraBackground() -> some View {
        modifier(PandoraBackgroundModifier())
    }
}

// MARK: - Navigation Bar Hidden

struct HiddenNavigationBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.inline)
    }
}

extension View {
    func hideNavigationBar() -> some View {
        modifier(HiddenNavigationBar())
    }
}

// MARK: - Loading State

struct LoadingModifier: ViewModifier {
    
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .opacity(isLoading ? 0.3 : 1.0)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: PandoraTheme.Colors.gold))
                    .scaleEffect(1.5)
            }
        }
    }
}

extension View {
    func loading(_ isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }
}

// MARK: - Error Alert

struct ErrorAlertModifier: ViewModifier {
    
    @Binding var error: Error?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<Error?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}

// MARK: - Haptic Feedback

struct HapticFeedbackModifier: ViewModifier {
    
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _, _ in
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
            }
    }
}

extension View {
    func hapticFeedback(
        style: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        trigger: Bool
    ) -> some View {
        modifier(HapticFeedbackModifier(style: style, trigger: trigger))
    }
}
