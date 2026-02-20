//
//  HubViewModel.swift
//  Pandora - Hub MicroApp
//
//  Created by Immanuel Hardjo on 16/02/26.
//  Enhanced with Clean Architecture patterns
//

import SwiftUI
import SwiftData

// MARK: - Hub ViewModel Protocol

/// Protocol defining HubViewModel interface for better testability
protocol HubViewModelProtocol: AnyObject {
    var microApps: [AnyMicroApp] { get }
    var filteredApps: [AnyMicroApp] { get }
    var searchText: String { get set }
    
    func findApp(id: String) -> AnyMicroApp?
    func registerMicroApp(_ app: AnyMicroApp)
    func unregisterMicroApp(id: String)
}

// MARK: - Hub ViewModel

/// ViewModel managing the Hub's state and MicroApp discovery
/// Follows MVVM pattern with protocol-oriented design
///
/// **Responsibilities**:
/// - Read registered MicroApps from the shared registry
/// - Provide search/filter functionality
/// - Handle dynamic app registration/unregistration
///
/// **Decoupling**: HubViewModel does NOT import or instantiate any
/// concrete MicroApp. It reads from `MicroAppRegistry`, which is
/// populated by `PandoraApp` at launch.
@Observable
final class HubViewModel: HubViewModelProtocol {
    
    // MARK: - Dependencies
    
    private let registry: MicroAppRegistryProtocol
    
    // MARK: - Properties
    
    /// The source of truth for all installed MicroApps
    private(set) var microApps: [AnyMicroApp] = []
    
    /// Search text for filtering apps
    var searchText: String = "" {
        didSet {
            updateFilteredApps()
        }
    }
    
    /// Filtered apps based on search text
    private(set) var filteredApps: [AnyMicroApp] = []
    
    // MARK: - Initialization
    
    /// Initialize with a registry (defaults to the shared singleton)
    /// - Parameter registry: The MicroApp registry to read apps from
    init(registry: MicroAppRegistryProtocol = MicroAppRegistry.shared) {
        self.registry = registry
        self.microApps = registry.registeredApps
        updateFilteredApps()
    }
    
    // MARK: - Public Methods
    
    /// Find an app by its unique identifier
    /// - Parameter id: The app's identifier
    /// - Returns: The MicroApp if found, nil otherwise
    func findApp(id: String) -> AnyMicroApp? {
        microApps.first { $0.id == id }
    }
    
    /// Register a new MicroApp dynamically
    /// - Parameter app: The MicroApp to register
    func registerMicroApp(_ app: AnyMicroApp) {
        guard !microApps.contains(where: { $0.id == app.id }) else {
            print("⚠️ MicroApp with id \(app.id) already registered")
            return
        }
        
        microApps.append(app)
        updateFilteredApps()
        print("✅ Registered MicroApp: \(app.metadata.name)")
    }
    
    /// Unregister a MicroApp by ID
    /// - Parameter id: The app's identifier to remove
    func unregisterMicroApp(id: String) {
        guard let appName = findApp(id: id)?.metadata.name else { return }
        
        microApps.removeAll { $0.id == id }
        updateFilteredApps()
        print("🗑️ Unregistered MicroApp: \(appName)")
    }
    
    /// Get MicroApps sorted by name
    func sortedApps() -> [AnyMicroApp] {
        filteredApps.sorted { $0.metadata.name < $1.metadata.name }
    }
    
    /// Get total count of registered apps
    var totalAppsCount: Int {
        microApps.count
    }
    
    /// Collects all SwiftData model types declared by registered MicroApps
    /// Used by PandoraApp to build the ModelContainer schema dynamically
    var allModelTypes: [any PersistentModel.Type] {
        microApps.flatMap { $0.modelTypes }
    }
    
    // MARK: - Private Methods
    
    /// Update filtered apps based on search text
    private func updateFilteredApps() {
        if searchText.isEmpty {
            filteredApps = microApps
        } else {
            filteredApps = microApps.filter { app in
                app.metadata.name.localizedCaseInsensitiveContains(searchText) ||
                app.metadata.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Hub ViewModel Factory

/// Factory for creating HubViewModel instances
enum HubViewModelFactory {
    
    /// Create a standard HubViewModel from the shared registry
    @MainActor
    static func makeViewModel() -> HubViewModel {
        HubViewModel(registry: MicroAppRegistry.shared)
    }
    
    /// Create a HubViewModel with a custom registry (useful for testing/previews)
    static func makeViewModel(registry: MicroAppRegistryProtocol) -> HubViewModel {
        HubViewModel(registry: registry)
    }
}
