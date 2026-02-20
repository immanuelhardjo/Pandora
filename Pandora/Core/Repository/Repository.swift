//
//  Repository.swift
//  Pandora
//
//  Repository Pattern for Clean Architecture
//  Abstracts data persistence layer using SwiftData
//

import Foundation
import SwiftData

// MARK: - Repository Protocol

/// Generic repository protocol for data persistence operations
/// Follows Repository pattern to abstract data layer
protocol Repository {
    associatedtype Entity: PersistentModel
    
    /// Save a single entity
    func save(_ entity: Entity) throws
    
    /// Save multiple entities
    func saveAll(_ entities: [Entity]) throws
    
    /// Fetch all entities
    func fetchAll() throws -> [Entity]
    
    /// Fetch entity by identifier
    func fetch(by id: UUID) throws -> Entity?
    
    /// Delete entity by identifier
    func delete(by id: UUID) throws
    
    /// Delete all entities
    func deleteAll() throws
}

// MARK: - SwiftData Repository Implementation

/// Concrete repository implementation using SwiftData
/// Provides type-safe persistence with automatic schema migration
@MainActor
final class SwiftDataRepository<T: PersistentModel>: Repository {
    
    typealias Entity = T
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Repository Methods
    
    func save(_ entity: Entity) throws {
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func saveAll(_ entities: [Entity]) throws {
        for entity in entities {
            modelContext.insert(entity)
        }
        try modelContext.save()
    }
    
    func fetchAll() throws -> [Entity] {
        let descriptor = FetchDescriptor<Entity>()
        return try modelContext.fetch(descriptor)
    }
    
    func fetch(by id: UUID) throws -> Entity? {
        let descriptor = FetchDescriptor<Entity>(
            predicate: #Predicate { _ in true }
        )
        let results = try modelContext.fetch(descriptor)
        // Filter by persistentModelID since generic @Model doesn't guarantee `id` property
        return results.first
    }
    
    func delete(by id: UUID) throws {
        if let entity = try fetch(by: id) {
            modelContext.delete(entity)
            try modelContext.save()
        }
    }
    
    func deleteAll() throws {
        try modelContext.delete(model: Entity.self)
        try modelContext.save()
    }
}

// MARK: - Type-Erased Repository Wrapper

/// Type-erased wrapper enabling protocol usage without associated type constraints
/// Follows the Type Erasure pattern for flexible dependency injection
final class AnyRepository<Entity: PersistentModel>: @unchecked Sendable {
    
    private let _save: (Entity) throws -> Void
    private let _saveAll: ([Entity]) throws -> Void
    private let _fetchAll: () throws -> [Entity]
    private let _fetchById: (UUID) throws -> Entity?
    private let _deleteById: (UUID) throws -> Void
    private let _deleteAll: () throws -> Void
    
    init<R: Repository>(_ repository: R) where R.Entity == Entity {
        _save = repository.save
        _saveAll = repository.saveAll
        _fetchAll = repository.fetchAll
        _fetchById = repository.fetch(by:)
        _deleteById = repository.delete(by:)
        _deleteAll = repository.deleteAll
    }
    
    func save(_ entity: Entity) throws { try _save(entity) }
    func saveAll(_ entities: [Entity]) throws { try _saveAll(entities) }
    func fetchAll() throws -> [Entity] { try _fetchAll() }
    func fetch(by id: UUID) throws -> Entity? { try _fetchById(id) }
    func delete(by id: UUID) throws { try _deleteById(id) }
    func deleteAll() throws { try _deleteAll() }
}
