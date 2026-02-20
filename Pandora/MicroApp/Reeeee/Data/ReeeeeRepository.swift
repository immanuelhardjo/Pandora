//
//  ReeeeeRepository.swift
//  Pandora - Reeeee MicroApp
//
//  Repository implementation specific to Reeeee feature
//  Uses SwiftData for persistence
//

import Foundation
import SwiftData

// MARK: - Reeeee Repository Factory

/// Factory for creating Reeeee-specific repositories
/// Returns a type-erased `AnyRepository` so consumers don't depend on concrete storage
enum ReeeeeRepositoryFactory {
    
    /// Create a type-erased repository for ReeeeeModel backed by SwiftData
    /// - Parameter modelContext: The SwiftData ModelContext from the environment
    /// - Returns: A type-erased repository for ReeeeeModel
    @MainActor
    static func makeRepository(modelContext: ModelContext) -> AnyRepository<ReeeeeModel> {
        let concrete = SwiftDataRepository<ReeeeeModel>(modelContext: modelContext)
        return AnyRepository(concrete)
    }
}
