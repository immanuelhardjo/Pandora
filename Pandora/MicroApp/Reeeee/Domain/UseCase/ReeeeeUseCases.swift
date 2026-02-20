//
//  ReeeeeUseCases.swift
//  Pandora - Reeeee MicroApp
//
//  Use Case / Interactor layer for Reeeee MicroApp
//  Business logic specific to the Reeeee feature
//
//  Note: Uses the generic UseCase protocol from Core/Protocol/UseCase.swift
//

import Foundation
import CoreMotion
import SwiftData

// MARK: - Motion Detection Use Cases

/// Use case for detecting freefall motion
struct DetectFreefallUseCase: UseCase {
    
    struct Request {
        let acceleration: CMAcceleration
        let threshold: Double
    }
    
    struct Response {
        let isInFreefall: Bool
        let gForce: Double
    }
    
    func execute(_ request: Request) async throws -> Response {
        let gForce = calculateGForce(from: request.acceleration)
        let isInFreefall = gForce < request.threshold
        
        return Response(isInFreefall: isInFreefall, gForce: gForce)
    }
    
    private func calculateGForce(from acceleration: CMAcceleration) -> Double {
        sqrt(
            pow(acceleration.x, 2) +
            pow(acceleration.y, 2) +
            pow(acceleration.z, 2)
        )
    }
}

/// Use case for detecting impact after freefall
struct DetectImpactUseCase: UseCase {
    
    struct Request {
        let acceleration: CMAcceleration
        let threshold: Double
    }
    
    struct Response {
        let hasImpact: Bool
        let gForce: Double
    }
    
    func execute(_ request: Request) async throws -> Response {
        let gForce = calculateGForce(from: request.acceleration)
        let hasImpact = gForce > request.threshold
        
        return Response(hasImpact: hasImpact, gForce: gForce)
    }
    
    private func calculateGForce(from acceleration: CMAcceleration) -> Double {
        sqrt(
            pow(acceleration.x, 2) +
            pow(acceleration.y, 2) +
            pow(acceleration.z, 2)
        )
    }
}

// MARK: - Data Management Use Cases

/// Use case for saving Reeeee records
struct SaveReeeeeRecordUseCase: UseCase {
    
    private let repository: AnyRepository<ReeeeeModel>
    
    init(repository: AnyRepository<ReeeeeModel>) {
        self.repository = repository
    }
    
    struct Request {
        let airtime: Double
        let date: Date
    }
    
    struct Response {
        let savedRecord: ReeeeeModel
    }
    
    func execute(_ request: Request) async throws -> Response {
        let record = ReeeeeModel(
            airtime: request.airtime,
            date: request.date
        )
        
        try repository.save(record)
        
        return Response(savedRecord: record)
    }
}

/// Use case for fetching all Reeeee records
struct FetchReeeeeHistoryUseCase: UseCase {
    
    private let repository: AnyRepository<ReeeeeModel>
    
    init(repository: AnyRepository<ReeeeeModel>) {
        self.repository = repository
    }
    
    struct Request {}
    
    struct Response {
        let records: [ReeeeeModel]
        let highScore: Double
    }
    
    func execute(_ request: Request) async throws -> Response {
        let records = try repository.fetchAll()
        let highScore = records.map { $0.airtime }.max() ?? 0.0
        
        return Response(records: records, highScore: highScore)
    }
}

/// Use case for clearing all Reeeee records
struct ClearReeeeeHistoryUseCase: UseCase {
    
    private let repository: AnyRepository<ReeeeeModel>
    
    init(repository: AnyRepository<ReeeeeModel>) {
        self.repository = repository
    }
    
    struct Request {}
    struct Response {}
    
    func execute(_ request: Request) async throws -> Response {
        try repository.deleteAll()
        return Response()
    }
}

// MARK: - Physics Calculation Use Case

/// Use case for calculating physics-based metrics
struct CalculatePhysicsMetricsUseCase: UseCase {
    
    struct Request {
        let airtime: Double
    }
    
    struct Response {
        let peakAltitude: Double
        let initialVelocity: Double
        let rank: String
    }
    
    func execute(_ request: Request) async throws -> Response {
        let gravity = 9.80665 // m/s²
        let timeInAscent = request.airtime / 2
        
        // Calculate peak altitude using kinematic equation
        let peakAltitude = 0.5 * gravity * pow(timeInAscent, 2)
        
        // Calculate initial velocity
        let initialVelocity = gravity * timeInAscent
        
        // Determine rank
        let rank = determineRank(airtime: request.airtime)
        
        return Response(
            peakAltitude: peakAltitude,
            initialVelocity: initialVelocity,
            rank: rank
        )
    }
    
    private func determineRank(airtime: Double) -> String {
        switch airtime {
        case ..<0.5: return "Weak Toss"
        case 0.5..<1.0: return "Solid Send"
        case 1.0..<1.5: return "Lunar Bound"
        default: return "God Tier"
        }
    }
}
