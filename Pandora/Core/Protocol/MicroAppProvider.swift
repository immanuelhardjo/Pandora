//
//  MicroAppProvider.swift
//  Pandora
//
//  Created by Immanuel Hardjo on 16/02/26.
//  Enhanced with Clean Architecture principles
//

import SwiftUI
import SwiftData

// MARK: - MicroApp Error Types

/// Errors that can occur during MicroApp lifecycle
enum MicroAppError: LocalizedError {
    case initializationFailed(reason: String)
    case viewCreationFailed
    case dependencyMissing(String)
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let reason):
            return "Failed to initialize MicroApp: \(reason)"
        case .viewCreationFailed:
            return "Failed to create MicroApp view"
        case .dependencyMissing(let dependency):
            return "Missing required dependency: \(dependency)"
        }
    }
}

// MARK: - MicroApp Metadata

/// Metadata describing a MicroApp's characteristics
struct MicroAppMetadata: Equatable {
    let id: String
    let name: String
    let iconName: String
    let tintColor: Color
    let version: String
    let description: String
    
    init(
        id: String,
        name: String,
        iconName: String,
        tintColor: Color,
        version: String = "1.0.0",
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.tintColor = tintColor
        self.version = version
        self.description = description
    }
    
    static func == (lhs: MicroAppMetadata, rhs: MicroAppMetadata) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.iconName == rhs.iconName &&
        lhs.version == rhs.version
    }
}

// MARK: - MicroApp Provider Protocol

/// Protocol defining a Pandora MicroApp
/// Follows the Factory and Strategy patterns for flexible app creation
protocol MicroAppProvider: Identifiable, Hashable where ID == String {
    
    /// Unique identifier for the MicroApp
    nonisolated var id: String { get }
    
    /// Human-readable metadata about the MicroApp
    var metadata: MicroAppMetadata { get }
    
    /// Creates and returns the entry view for the MicroApp
    /// Using associatedtype instead of AnyView for better type safety
    associatedtype ContentView: View
    
    /// Factory method to create the MicroApp's root view
    @ViewBuilder func makeView() -> ContentView
    
    /// SwiftData model types this MicroApp needs persisted
    /// Return an empty array if the MicroApp has no persistent models
    var modelTypes: [any PersistentModel.Type] { get }
    
    /// Optional lifecycle hook called when app is about to be presented
    func onAppear()
    
    /// Optional lifecycle hook called when app is about to disappear
    func onDisappear()
}

// MARK: - Default Protocol Implementations

extension MicroAppProvider {
    
    nonisolated var id: String {
        metadata.id
    }
    
    // Default lifecycle implementations (can be overridden)
    func onAppear() {
        // Default: no-op
    }
    
    func onDisappear() {
        // Default: no-op
    }
    
    // Default: no persistent models
    var modelTypes: [any PersistentModel.Type] { [] }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Type-Erased MicroApp Wrapper

/// Type-erased wrapper for MicroAppProvider to enable heterogeneous collections
/// This allows storing different MicroApp types in the same array
struct AnyMicroApp: MicroAppProvider {
    
    let metadata: MicroAppMetadata
    let modelTypes: [any PersistentModel.Type]
    private let _makeView: () -> AnyView
    private let _onAppear: () -> Void
    private let _onDisappear: () -> Void
    
    init<T: MicroAppProvider>(_ microApp: T) {
        self.metadata = microApp.metadata
        self.modelTypes = microApp.modelTypes
        self._makeView = { AnyView(microApp.makeView()) }
        self._onAppear = microApp.onAppear
        self._onDisappear = microApp.onDisappear
    }
    
    func makeView() -> AnyView {
        _makeView()
    }
    
    func onAppear() {
        _onAppear()
    }
    
    func onDisappear() {
        _onDisappear()
    }
}

// MARK: - Concrete MicroApp: Reeeee

/// Concrete implementation of the Reeeee (Yeet) MicroApp
/// This is now defined in the Reeeee module itself
/// See: MicroApp/Reeeee/ReeeeeMicroApp.swift

