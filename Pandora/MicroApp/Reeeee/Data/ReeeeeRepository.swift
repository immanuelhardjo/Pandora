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

/// Factory for creating Reeeee-specific SwiftData repositories
/// Keeps repository creation logic within the MicroApp module
enum ReeeeeRepositoryFactory {
    
    /// Create a SwiftData-backed repository for ReeeeeModel
    /// - Parameter modelContext: The SwiftData ModelContext from the environment
    /// - Returns: A type-erased repository for ReeeeeModel
    @MainActor
    static func makeRepository(modelContext: ModelContext) -> SwiftDataRepository<ReeeeeModel> {
        SwiftDataRepository(modelContext: modelContext)
    }
}
