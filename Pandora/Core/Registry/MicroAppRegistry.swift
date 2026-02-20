//
//  MicroAppRegistry.swift
//  Pandora
//
//  Centralized registry for all MicroApps
//  Decouples app discovery from any specific module
//

import Foundation

// MARK: - MicroApp Registry Protocol

/// Protocol for the MicroApp registry
/// Allows different registration strategies (static, remote config, etc.)
protocol MicroAppRegistryProtocol {
    /// All registered MicroApps
    var registeredApps: [AnyMicroApp] { get }
}

// MARK: - MicroApp Registry

/// Central registry that collects all MicroApp registrations
/// Each MicroApp registers itself here — no module needs to know about siblings
///
/// **Usage:**
/// ```swift
/// // In app setup:
/// MicroAppRegistry.shared.register(ReeeeeMicroApp())
///
/// // In HubViewModel (receives apps via init):
/// let viewModel = HubViewModel(registry: MicroAppRegistry.shared)
/// ```
@MainActor
final class MicroAppRegistry: MicroAppRegistryProtocol {
    
    // MARK: - Singleton
    
    static let shared = MicroAppRegistry()
    
    // MARK: - Properties
    
    private(set) var registeredApps: [AnyMicroApp] = []
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Registration
    
    /// Register a MicroApp with the registry
    /// - Parameter app: Any concrete MicroApp conforming to MicroAppProvider
    func register<T: MicroAppProvider>(_ app: T) {
        let wrapped = AnyMicroApp(app)
        
        guard !registeredApps.contains(where: { $0.id == wrapped.id }) else {
            print("⚠️ MicroApp '\(wrapped.metadata.name)' already registered, skipping")
            return
        }
        
        registeredApps.append(wrapped)
        print("✅ Registered MicroApp: \(wrapped.metadata.name)")
    }
    
    /// Remove a MicroApp from the registry
    /// - Parameter id: The MicroApp's unique identifier
    func unregister(id: String) {
        registeredApps.removeAll { $0.id == id }
    }
    
    /// Reset all registrations (useful for testing)
    func reset() {
        registeredApps.removeAll()
    }
}
