//
//  HubViewModel.swift
//  Pandora - Hub MicroApp
//
//  Created by Immanuel Hardjo on 16/02/26.
//  Enhanced with Clean Architecture patterns
//

import SwiftUI

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

/// ViewModel managing the Hub's state and MicroApp registry
/// Follows MVVM pattern with protocol-oriented design
///
/// **Responsibilities**:
/// - Maintain registry of all installed MicroApps
/// - Provide search/filter functionality
/// - Handle dynamic app registration/unregistration
@Observable
final class HubViewModel: HubViewModelProtocol {
    
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
    
    init() {
        registerDefaultMicroApps()
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
    
    // MARK: - Private Methods
    
    /// Register all default MicroApps on initialization
    /// This is where you manually "unlock" new apps in the box
    private func registerDefaultMicroApps() {
        // Register Reeeee MicroApp
        let reeeeeApp = AnyMicroApp(ReeeeeMicroApp())
        microApps.append(reeeeeApp)
        
        // Add more apps here as you build them
        // Example:
        // let newApp = AnyMicroApp(NewMicroApp())
        // microApps.append(newApp)
        
        print("✅ Registered \(microApps.count) MicroApp(s)")
    }
    
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
    
    /// Create a standard HubViewModel
    static func makeViewModel() -> HubViewModel {
        HubViewModel()
    }
    
    /// Create a HubViewModel with pre-registered apps (useful for testing)
    static func makeViewModel(with apps: [AnyMicroApp]) -> HubViewModel {
        let viewModel = HubViewModel()
        apps.forEach { viewModel.registerMicroApp($0) }
        return viewModel
    }
}
