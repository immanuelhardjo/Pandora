//
//  Router.swift
//  Pandora
//
//  Created by Immanuel Hardjo on 16/02/26.
//  Enhanced with Coordinator pattern and better navigation management
//

import SwiftUI

// MARK: - Route Protocol

/// Protocol for type-safe routing
protocol Route: Hashable, Identifiable {
    var id: String { get }
}

// MARK: - App Routes

/// All available routes in the Pandora application
enum AppRoute: Route {
    case hub
    case launchMicroApp(id: String)
    
    var id: String {
        switch self {
        case .hub:
            return "hub"
        case .launchMicroApp(let id):
            return "microapp_\(id)"
        }
    }
}

// MARK: - Navigation Action

/// Represents different navigation actions that can be performed
enum NavigationAction {
    case push(AppRoute)
    case pop
    case popToRoot
    case replace(AppRoute)
    case replaceStack([AppRoute])
}

// MARK: - Router Protocol

/// Protocol defining navigation capabilities
/// Follows Coordinator pattern for centralized navigation logic
protocol RouterProtocol: AnyObject {
    var path: NavigationPath { get set }
    
    /// Navigate to a specific route
    func navigate(to route: AppRoute)
    
    /// Navigate to a MicroApp by ID
    func navigateToMicroApp(_ id: String)
    
    /// Go back one screen
    func goBack()
    
    /// Return to the hub (root)
    func backToHub()
    
    /// Get current route depth
    func currentDepth() -> Int
    
    /// Check if can go back
    func canGoBack() -> Bool
}

// MARK: - Router Implementation

/// Main router implementation following the Coordinator pattern
/// Manages all navigation within the Pandora app
@Observable
final class Router: RouterProtocol {
    
    // MARK: - Properties
    
    var path = NavigationPath()
    
    // MARK: - Private Properties
    
    private var navigationHistory: [AppRoute] = []
    
    // MARK: - Public Methods
    
    func navigate(to route: AppRoute) {
        path.append(route)
        navigationHistory.append(route)
        logNavigation(action: "Navigate to", route: route)
    }
    
    func navigateToMicroApp(_ id: String) {
        let route = AppRoute.launchMicroApp(id: id)
        navigate(to: route)
    }
    
    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
        
        if !navigationHistory.isEmpty {
            let removed = navigationHistory.removeLast()
            logNavigation(action: "Back from", route: removed)
        }
    }
    
    func backToHub() {
        path = NavigationPath()
        navigationHistory.removeAll()
        logNavigation(action: "Reset to", route: .hub)
    }
    
    func currentDepth() -> Int {
        return path.count
    }
    
    func canGoBack() -> Bool {
        return !path.isEmpty
    }
    
    // MARK: - Advanced Navigation
    
    /// Replace the current screen with a new route
    func replace(with route: AppRoute) {
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(route)
        
        if !navigationHistory.isEmpty {
            navigationHistory.removeLast()
        }
        navigationHistory.append(route)
        
        logNavigation(action: "Replace with", route: route)
    }
    
    /// Replace entire navigation stack
    func replaceStack(with routes: [AppRoute]) {
        path = NavigationPath()
        navigationHistory.removeAll()
        
        routes.forEach { route in
            path.append(route)
            navigationHistory.append(route)
        }
        
        print("📱 Navigation stack replaced with \(routes.count) routes")
    }
    
    /// Get navigation history
    func getNavigationHistory() -> [AppRoute] {
        return navigationHistory
    }
    
    // MARK: - Deep Linking Support
    
    /// Handle deep link navigation
    /// - Parameter url: Deep link URL
    /// - Returns: Boolean indicating if the URL was handled
    func handleDeepLink(_ url: URL) -> Bool {
        // Example: pandora://microapp/com.pandora.reeeee
        guard url.scheme == "pandora" else { return false }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        guard pathComponents.count >= 2,
              pathComponents[0] == "microapp" else {
            return false
        }
        
        let microAppId = pathComponents[1]
        navigateToMicroApp(microAppId)
        
        return true
    }
    
    // MARK: - Logging
    
    private func logNavigation(action: String, route: AppRoute) {
        #if DEBUG
        print("🧭 \(action): \(route.id) | Depth: \(currentDepth())")
        #endif
    }
}

// MARK: - Router Factory

/// Factory for creating Router instances with proper configuration
enum RouterFactory {
    
    static func makeRouter() -> Router {
        Router()
    }
    
    /// Create router with initial route
    static func makeRouter(initialRoute: AppRoute) -> Router {
        let router = Router()
        router.navigate(to: initialRoute)
        return router
    }
}
