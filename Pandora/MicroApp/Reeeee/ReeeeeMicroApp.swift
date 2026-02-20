//
//  ReeeeeMicroApp.swift
//  Pandora - Reeeee MicroApp
//
//  Entry point for the Reeeee (Phone Yeet) MicroApp
//  This is the single public interface for this feature module
//

import SwiftUI
import SwiftData

// MARK: - Reeeee MicroApp

/// Concrete implementation of the Reeeee (Phone Yeet) MicroApp
/// 
/// **Feature Description:**
/// Tracks your phone's airtime using CoreMotion sensors, calculates physics metrics,
/// and maintains a history of all your "yeets" with rankings.
///
/// **Architecture:**
/// - Domain: Business logic, use cases, and domain models
/// - Data: SwiftData repository for persistence
/// - Presentation: MVVM with SwiftUI views
struct ReeeeeMicroApp: MicroAppProvider {
    
    // MARK: - Metadata
    
    let metadata = MicroAppMetadata(
        id: "com.pandora.reeeee",
        name: "REEEEE",
        iconName: "iphone.motion",
        tintColor: .red,
        version: "1.0.0",
        description: "Yeet your phone to reeeee!"
    )
    
    // MARK: - View Factory
    
    func makeView() -> some View {
        // Use a wrapper view that resolves SwiftData ModelContext from the environment
        ReeeeeContainerView()
    }
    
    // MARK: - Lifecycle Hooks
    
    func onAppear() {
        print("🚀 Reeeee MicroApp launched")
    }
    
    func onDisappear() {
        print("👋 Reeeee MicroApp closed")
    }
}

// MARK: - Container View

/// Intermediate container that resolves the ModelContext from SwiftUI environment
/// and creates the ViewModel with the SwiftData repository
/// This bridges the SwiftUI environment with the ViewModel dependency injection
private struct ReeeeeContainerView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ReeeeeViewModel?
    
    var body: some View {
        Group {
            if let viewModel {
                ReeeeeView(viewModel: viewModel)
            } else {
                ProgressView()
                    .pandoraBackground()
            }
        }
        .onAppear {
            if viewModel == nil {
                let repository = ReeeeeRepositoryFactory.makeRepository(modelContext: modelContext)
                viewModel = ReeeeeViewModelFactory.makeViewModel(repository: repository)
            }
        }
    }
}
