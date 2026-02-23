//
//  WallSenseUseCases.swift
//  Pandora - WallSense MicroApp
//
//  Use Case / Interactor layer for WallSense MicroApp
//  Business logic specific to the WallSense feature
//

import Foundation
import SwiftData

// MARK: - Calibration Use Case

/// Calculates baseline magnetic field from calibration readings
/// Returns both total magnitude baseline and per-axis (X, Y, Z) baselines
/// Per-axis baselines allow directional anomaly detection during scanning
struct CalibrateBaselineUseCase: SyncUseCase {
    
    struct Request {
        let readings: [MagneticReading]
    }
    
    struct Response {
        let baselineMagnitude: Double
        let baselineX: Double
        let baselineY: Double
        let baselineZ: Double
        let noiseFloor: Double
    }
    
    func execute(_ request: Request) throws -> Response {
        guard !request.readings.isEmpty else {
            throw WallSenseError.insufficientData
        }
        
        let count = Double(request.readings.count)
        
        let magnitudes = request.readings.map(\.magnitude)
        let averageMagnitude = magnitudes.reduce(0, +) / count
        
        // Per-axis baselines (average of each axis during calibration)
        let averageX = request.readings.map(\.x).reduce(0, +) / count
        let averageY = request.readings.map(\.y).reduce(0, +) / count
        let averageZ = request.readings.map(\.z).reduce(0, +) / count
        
        // Noise floor = standard deviation of magnitude readings during calibration
        let variance = magnitudes.map { pow($0 - averageMagnitude, 2) }.reduce(0, +) / count
        let standardDeviation = sqrt(variance)
        
        return Response(
            baselineMagnitude: averageMagnitude,
            baselineX: averageX,
            baselineY: averageY,
            baselineZ: averageZ,
            noiseFloor: standardDeviation * 2 // 2-sigma threshold
        )
    }
}

// MARK: - Classify Anomaly Use Case

/// Classifies a magnetic anomaly based on signal characteristics
struct ClassifyAnomalyUseCase: SyncUseCase {
    
    struct Request {
        let readings: [MagneticReading]
        let baseline: Double
        let noiseFloor: Double
    }
    
    struct Response {
        let classification: AnomalyClassification
        let peakDeviation: Double
        let threatLevel: ThreatLevel
        let isOscillating: Bool
    }
    
    func execute(_ request: Request) throws -> Response {
        let deviations = request.readings.map(\.deviation)
        let peakDeviation = deviations.max() ?? 0
        
        // Count how many consecutive readings are above noise floor = "spread"
        let aboveNoise = deviations.filter { $0 > request.noiseFloor }
        let spreadWidth = aboveNoise.count
        
        // Detect AC oscillation: look for sign alternation in the delta between readings
        let isOscillating = detectOscillation(deviations: deviations)
        
        let classification = AnomalyClassification.classify(
            deviation: peakDeviation,
            isOscillating: isOscillating,
            spreadWidth: spreadWidth
        )
        
        let threatLevel = ThreatLevel.classify(deviation: peakDeviation)
        
        return Response(
            classification: classification,
            peakDeviation: peakDeviation,
            threatLevel: threatLevel,
            isOscillating: isOscillating
        )
    }
    
    /// Detect oscillation pattern in deviations (indicates AC current)
    /// Looks for frequent sign changes in the rate of change
    private func detectOscillation(deviations: [Double]) -> Bool {
        guard deviations.count > 10 else { return false }
        
        var signChanges = 0
        var previousDelta: Double?
        
        for i in 1..<deviations.count {
            let delta = deviations[i] - deviations[i - 1]
            if let prev = previousDelta, prev * delta < 0 {
                signChanges += 1
            }
            previousDelta = delta
        }
        
        // If more than 30% of deltas change sign, it's oscillating
        let ratio = Double(signChanges) / Double(deviations.count - 2)
        return ratio > 0.3
    }
}

// MARK: - Save Scan Use Case

/// Saves a completed wall scan to the repository
struct SaveWallScanUseCase: UseCase {
    
    private let repository: AnyRepository<WallScanModel>
    
    init(repository: AnyRepository<WallScanModel>) {
        self.repository = repository
    }
    
    struct Request {
        let locationName: String
        let peakDeviation: Double
        let averageDeviation: Double
        let baselineMagnitude: Double
        let anomalyCount: Int
        let primaryClassification: AnomalyClassification
        let threatLevel: ThreatLevel
        let scanDuration: Double
    }
    
    struct Response {
        let savedScan: WallScanModel
    }
    
    func execute(_ request: Request) async throws -> Response {
        let scan = WallScanModel(
            locationName: request.locationName,
            peakDeviation: request.peakDeviation,
            averageDeviation: request.averageDeviation,
            baselineMagnitude: request.baselineMagnitude,
            anomalyCount: request.anomalyCount,
            primaryClassification: request.primaryClassification.rawValue,
            threatLevelRaw: request.threatLevel.rawValue,
            scanDuration: request.scanDuration
        )
        
        try repository.save(scan)
        return Response(savedScan: scan)
    }
}

// MARK: - Fetch Scan History Use Case

/// Fetches all saved wall scans
struct FetchWallScanHistoryUseCase: UseCase {
    
    private let repository: AnyRepository<WallScanModel>
    
    init(repository: AnyRepository<WallScanModel>) {
        self.repository = repository
    }
    
    struct Request {}
    
    struct Response {
        let scans: [WallScanModel]
        let totalAnomalies: Int
    }
    
    func execute(_ request: Request) async throws -> Response {
        let scans = try repository.fetchAll()
        let totalAnomalies = scans.reduce(0) { $0 + $1.anomalyCount }
        
        return Response(scans: scans, totalAnomalies: totalAnomalies)
    }
}

// MARK: - Clear History Use Case

/// Clears all saved wall scans
struct ClearWallScanHistoryUseCase: SimpleUseCase {
    
    private let repository: AnyRepository<WallScanModel>
    
    init(repository: AnyRepository<WallScanModel>) {
        self.repository = repository
    }
    
    func execute() async throws {
        try repository.deleteAll()
    }
}

// MARK: - WallSense Errors

enum WallSenseError: LocalizedError {
    case insufficientData
    case magnetometerUnavailable
    case calibrationFailed
    
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "Not enough sensor data for analysis"
        case .magnetometerUnavailable:
            return "Magnetometer sensor is not available on this device"
        case .calibrationFailed:
            return "Failed to calibrate baseline magnetic field"
        }
    }
}
