//
//  UseCase.swift
//  Pandora
//
//  Generic UseCase protocol for Clean Architecture
//  This belongs in Core because it's a reusable abstraction
//

import Foundation

// MARK: - Use Case Protocol

/// Generic protocol for all use cases following the Command pattern
/// This is a shared abstraction that all MicroApps can adopt
/// 
/// **Usage in MicroApps:**
/// ```swift
/// struct SaveRecordUseCase: UseCase {
///     struct Request { let data: String }
///     struct Response { let success: Bool }
///     
///     func execute(_ request: Request) async throws -> Response {
///         // Business logic here
///     }
/// }
/// ```
protocol UseCase {
    associatedtype Request
    associatedtype Response
    
    /// Execute the use case with a given request
    /// - Parameter request: Input data for the use case
    /// - Returns: Response containing the result
    /// - Throws: Business logic errors
    func execute(_ request: Request) async throws -> Response
}

// MARK: - Synchronous Use Case

/// Protocol for use cases that don't require async operations
protocol SyncUseCase {
    associatedtype Request
    associatedtype Response
    
    /// Execute the use case synchronously
    /// - Parameter request: Input data for the use case
    /// - Returns: Response containing the result
    /// - Throws: Business logic errors
    func execute(_ request: Request) throws -> Response
}

// MARK: - No-Input Use Case

/// Protocol for use cases that don't require input parameters
protocol NoInputUseCase {
    associatedtype Response
    
    /// Execute the use case without input
    /// - Returns: Response containing the result
    /// - Throws: Business logic errors
    func execute() async throws -> Response
}

// MARK: - No-Output Use Case

/// Protocol for use cases that perform actions without returning data
protocol NoOutputUseCase {
    associatedtype Request
    
    /// Execute the use case without expecting a response
    /// - Parameter request: Input data for the use case
    /// - Throws: Business logic errors
    func execute(_ request: Request) async throws
}

// MARK: - Simple Use Case

/// Protocol for use cases with no input or output (fire-and-forget)
protocol SimpleUseCase {
    /// Execute the use case
    /// - Throws: Business logic errors
    func execute() async throws
}
