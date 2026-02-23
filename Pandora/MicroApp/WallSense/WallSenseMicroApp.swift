//
//  WallSenseMicroApp.swift
//  Pandora - WallSense MicroApp
//
//  Entry point for the WallSense (Wall Scanner) MicroApp
//  This is the single public interface for this feature module
//

import SwiftUI
import SwiftData

// MARK: - WallSense MicroApp

/// Concrete implementation of the WallSense (Wall Scanner) MicroApp
///
/// **Feature Description:**
/// Detects metal studs, wiring, pipes, and rebar behind walls using the
/// iPhone's CMMagnetometer. Provides real-time magnetic field visualization,
/// anomaly classification, and scan history persistence.
///
/// **Architecture:**
/// - Domain: Business logic, use cases, and domain models
/// - Data: SwiftData repository for persistence
/// - Presentation: MVVM with SwiftUI views
struct WallSenseMicroApp: MicroAppProvider {
    
    // MARK: - Metadata
    
    let metadata = MicroAppMetadata(
        id: "com.pandora.wallsense",
        name: "WallSense",
        iconName: "sensor.tag.radiowaves.forward",
        tintColor: .cyan,
        version: "1.0.0",
        description: "X-ray vision for your walls"
    )
    
    // MARK: - SwiftData Models
    
    /// SwiftData models this MicroApp requires for persistence
    var modelTypes: [any PersistentModel.Type] {
        [WallScanModel.self]
    }
    
    // MARK: - View Factory
    
    func makeView() -> some View {
        // Use a wrapper view that resolves SwiftData ModelContext from the environment
        WallSenseContainerView()
    }
    
    // MARK: - Lifecycle Hooks
    
    func onAppear() {
        print("🔍 WallSense MicroApp launched")
    }
    
    func onDisappear() {
        print("👋 WallSense MicroApp closed")
    }
}

// MARK: - Container View

/// Intermediate container that resolves the ModelContext from SwiftUI environment
/// and creates the ViewModel with the SwiftData repository
/// This bridges the SwiftUI environment with the ViewModel dependency injection
private struct WallSenseContainerView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WallSenseViewModel?
    
    var body: some View {
        Group {
            if let viewModel {
                WallSenseView(viewModel: viewModel)
            } else {
                ProgressView()
                    .pandoraBackground()
            }
        }
        .onAppear {
            if viewModel == nil {
                let repository = WallSenseRepositoryFactory.makeRepository(modelContext: modelContext)
                viewModel = WallSenseViewModelFactory.makeViewModel(repository: repository)
            }
        }
    }
}
