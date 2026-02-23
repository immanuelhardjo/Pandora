//
//  WallSenseRepository.swift
//  Pandora - WallSense MicroApp
//
//  Repository implementation specific to WallSense feature
//  Uses SwiftData for persistence via factory pattern
//

import Foundation
import SwiftData

// MARK: - WallSense Repository Factory

/// Factory for creating WallSense-specific repositories
/// Returns a type-erased `AnyRepository` so consumers don't depend on concrete storage
enum WallSenseRepositoryFactory {
    
    /// Create a type-erased repository for WallScanModel backed by SwiftData
    /// - Parameter modelContext: The SwiftData ModelContext from the environment
    /// - Returns: A type-erased repository for WallScanModel
    @MainActor
    static func makeRepository(modelContext: ModelContext) -> AnyRepository<WallScanModel> {
        let concrete = SwiftDataRepository<WallScanModel>(modelContext: modelContext)
        return AnyRepository(concrete)
    }
}
