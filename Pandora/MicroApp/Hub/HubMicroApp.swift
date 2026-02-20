//
//  HubMicroApp.swift
//  Pandora - Hub MicroApp
//
//  Entry point for the Hub MicroApp
//  The Hub is the main launcher for all other MicroApps
//

import SwiftUI

// MARK: - Hub MicroApp

/// The Hub MicroApp serves as the main launcher and discovery interface
/// for all installed MicroApps in the Pandora ecosystem.
///
/// **Special Note**: Unlike other MicroApps, the Hub is always active
/// and serves as the root navigation point.
///
/// **Architecture**:
/// - Presentation: MVVM with MicroApp registry
/// - No Domain/Data layers needed (Hub doesn't have business logic)
struct HubMicroApp: MicroAppProvider {
    
    // MARK: - Metadata
    
    let metadata = MicroAppMetadata(
        id: "com.pandora.hub",
        name: "Hub",
        iconName: "square.grid.2x2",
        tintColor: PandoraTheme.Colors.gold,
        version: "1.0.0",
        description: "Main launcher for all MicroApps"
    )
    
    // MARK: - View Factory
    
    func makeView() -> some View {
        // Hub uses environment-injected ViewModel from App level
        // since it needs to be shared across navigation
        HubView()
    }
    
    // MARK: - Lifecycle Hooks
    
    func onAppear() {
        print("🏠 Hub MicroApp launched")
    }
    
    func onDisappear() {
        print("👋 Hub MicroApp closed")
    }
}
