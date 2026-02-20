//
//  DIContainer.swift
//  Pandora
//
//  Implements Service Locator pattern for better testability and loose coupling
//

import Foundation

/// Main dependency injection container following the Service Locator pattern
/// This provides centralized dependency management and supports both singleton and factory registrations
@MainActor
final class DIContainer {
    
    // MARK: - Singleton
    
    static let shared = DIContainer()
    
    // MARK: - Properties
    
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Registration Methods
    
    /// Register a singleton service
    /// - Parameters:
    ///   - type: The protocol or type to register
    ///   - service: The concrete instance
    func register<T>(_ type: T.Type, service: T) {
        let key = String(describing: type)
        services[key] = service
    }
    
    /// Register a factory for creating new instances
    /// - Parameters:
    ///   - type: The protocol or type to register
    ///   - factory: Closure that creates a new instance
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    // MARK: - Resolution Methods
    
    /// Resolve a service from the container
    /// - Parameter type: The type to resolve
    /// - Returns: The registered instance or factory-created instance
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        // First check for registered singleton
        if let service = services[key] as? T {
            return service
        }
        
        // Then check for factory
        if let factory = factories[key] as? () -> T {
            return factory()
        }
        
        fatalError("❌ No registration found for \(key). Did you forget to register it in DIContainer?")
    }
    
    /// Optionally resolve a service (returns nil if not registered)
    /// - Parameter type: The type to resolve
    /// - Returns: The registered instance or nil
    func resolveOptional<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        if let service = services[key] as? T {
            return service
        }
        
        if let factory = factories[key] as? () -> T {
            return factory()
        }
        
        return nil
    }
    
    // MARK: - Utility Methods
    
    /// Reset all registrations (useful for testing)
    func reset() {
        services.removeAll()
        factories.removeAll()
    }
}

// MARK: - Property Wrapper for Dependency Injection

/// Property wrapper for automatic dependency injection
/// Usage: @Injected var router: RouterProtocol
@propertyWrapper
struct Injected<T> {
    
    private let container: DIContainer
    
    var wrappedValue: T {
        container.resolve(T.self)
    }
    
    init(container: DIContainer = .shared) {
        self.container = container
    }
}
