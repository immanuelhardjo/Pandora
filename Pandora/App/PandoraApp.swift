//
//  PandoraApp.swift
//  Pandora
//
//  Created by Immanuel Hardjo on 16/02/26.
//

import SwiftUI
import SwiftData

// MARK: - Pandora App

/// Main application entry point
/// Implements Clean Architecture with proper dependency injection setup
/// Uses SwiftData for persistence via ModelContainer
@main
struct PandoraApp: App {
    
    // MARK: - State

    @State private var router: Router
    @State private var hubViewModel: HubViewModel
    
    // MARK: - SwiftData
    
    /// Shared ModelContainer for all SwiftData models
    /// Configured with automatic schema migration
    private let modelContainer: ModelContainer
    
    // MARK: - Initialization
    
    init() {
        // 1. Register all MicroApps with the shared registry
        //    This is the ONLY place that knows about concrete MicroApp types.
        //    Adding a new MicroApp = one line here.
        Self.registerMicroApps()
        
        // 2. Initialize dependencies (reads from registry automatically)
        let router = RouterFactory.makeRouter()
        let hubViewModel = HubViewModelFactory.makeViewModel()
        
        self.router = router
        self.hubViewModel = hubViewModel
        
        // 3. Build SwiftData schema dynamically from registered MicroApps
        let allModelTypes = hubViewModel.allModelTypes
        
        // Ensure Application Support directory exists before CoreData tries to
        // create default.store — prevents noisy "Failed to stat path" errors on first launch
        let fileManager = FileManager.default
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            if !fileManager.fileExists(atPath: appSupportURL.path) {
                try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            }
        }
        
        do {
            let schema = Schema(allModelTypes)
            let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("❌ Failed to create ModelContainer: \(error)")
        }
        
        // 4. Setup core dependencies
        Self.setupCoreDependencies()
    }
    
    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HubView()
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .environment(router)
            .environment(hubViewModel)
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
        .modelContainer(modelContainer)
    }
    
    // MARK: - Destination Routing
    
    /// Creates the appropriate view for a given route
    /// Implements Strategy pattern for route handling
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .hub:
            HubView()
            
        case .launchMicroApp(let id):
            if let app = hubViewModel.findApp(id: id) {
                app.makeView()
                    .environment(router)
                    .onAppear {
                        app.onAppear()
                    }
                    .onDisappear {
                        app.onDisappear()
                    }
            } else {
                ErrorView(
                    title: "App Not Found",
                    message: "The requested MicroApp could not be found.",
                    icon: "exclamationmark.triangle"
                )
            }
        }
    }
    
    // MARK: - MicroApp Registration
    
    /// Register all MicroApps with the shared registry
    /// This is the **composition root** — the single place that knows about
    /// concrete MicroApp types. Adding a new MicroApp = one line here.
    @MainActor
    private static func registerMicroApps() {
        let registry = MicroAppRegistry.shared
        
        registry.register(ReeeeeMicroApp())
        registry.register(WallSenseMicroApp())
        
        // Add new MicroApps here:
        // registry.register(NewFeatureMicroApp())
    }
    
    // MARK: - Dependency Injection Setup
    
    /// Configure core dependencies only
    /// MicroApps register their own dependencies on-demand
    private static func setupCoreDependencies() {
        // Register only shared/core services here
        // Examples:
        // - Analytics service
        // - Network client
        // - Logging service
        // - Theme manager
        
        print("✅ Core dependencies configured")
    }
    
    // MARK: - Deep Link Handling
    
    /// Handle incoming deep links
    /// - Parameter url: The deep link URL
    private func handleDeepLink(_ url: URL) {
        let handled = router.handleDeepLink(url)
        
        if handled {
            print("🔗 Deep link handled: \(url)")
        } else {
            print("⚠️ Could not handle deep link: \(url)")
        }
    }
}

// MARK: - Error View

/// Generic error view for displaying failures gracefully
struct ErrorView: View {
    
    let title: String
    let message: String
    let icon: String
    
    @Environment(Router.self) private var router
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(PandoraTheme.Colors.gold)
            
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            PandoraButton("Back to Hub", icon: "house.fill") {
                router.backToHub()
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .pandoraBackground()
    }
}
