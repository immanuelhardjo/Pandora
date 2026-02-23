//
//  WallScanModel.swift
//  Pandora - WallSense MicroApp
//
//  Domain model representing a wall scan session with anomaly detection
//  Persisted with SwiftData
//

import Foundation
import SwiftData

// MARK: - Wall Scan Domain Model

/// Domain model representing a single wall scan session
/// Persisted via SwiftData using the @Model macro
/// Contains magnetic field readings and classified anomalies
@Model
final class WallScanModel: Identifiable {
    
    // MARK: - Persisted Properties
    
    /// Unique identifier for the scan
    @Attribute(.unique) var id: UUID
    
    /// User-given name for the scan location
    var locationName: String
    
    /// Timestamp of when the scan was performed
    var date: Date
    
    /// Peak magnetic deviation recorded during the scan (µT above baseline)
    var peakDeviation: Double
    
    /// Average magnetic deviation during the scan (µT)
    var averageDeviation: Double
    
    /// Baseline magnetic field strength at calibration (µT)
    var baselineMagnitude: Double
    
    /// Number of anomalies detected during this scan
    var anomalyCount: Int
    
    /// Classification of the strongest anomaly found
    var primaryClassification: String
    
    /// Threat level string ("safe", "low", "moderate", "high", "extreme")
    var threatLevelRaw: String
    
    /// Duration of the scan in seconds
    var scanDuration: Double
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        locationName: String,
        date: Date = Date(),
        peakDeviation: Double,
        averageDeviation: Double,
        baselineMagnitude: Double,
        anomalyCount: Int,
        primaryClassification: String,
        threatLevelRaw: String,
        scanDuration: Double
    ) {
        self.id = id
        self.locationName = locationName
        self.date = date
        self.peakDeviation = peakDeviation
        self.averageDeviation = averageDeviation
        self.baselineMagnitude = baselineMagnitude
        self.anomalyCount = anomalyCount
        self.primaryClassification = primaryClassification
        self.threatLevelRaw = threatLevelRaw
        self.scanDuration = scanDuration
    }
    
    // MARK: - Computed Properties
    
    /// Threat level enum derived from raw string
    var threatLevel: ThreatLevel {
        ThreatLevel(rawValue: threatLevelRaw) ?? .safe
    }
    
    /// User-friendly formatted date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Summary string for display
    var summary: String {
        if anomalyCount == 0 {
            return "No metal detected"
        }
        return "\(anomalyCount) anomal\(anomalyCount == 1 ? "y" : "ies") • \(primaryClassification)"
    }
}

// MARK: - Threat Level

/// Classification of danger level based on magnetic deviation
enum ThreatLevel: String, CaseIterable {
    case safe = "safe"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case extreme = "extreme"
    
    /// Classify threat level from magnetic deviation in µT
    static func classify(deviation: Double) -> ThreatLevel {
        switch deviation {
        case ..<5:     return .safe
        case 5..<15:   return .low
        case 15..<30:  return .moderate
        case 30..<60:  return .high
        default:       return .extreme
        }
    }
    
    var label: String {
        switch self {
        case .safe:     return "ALL CLEAR"
        case .low:      return "FAINT SIGNAL"
        case .moderate: return "METAL DETECTED"
        case .high:     return "STRONG PRESENCE"
        case .extreme:  return "⚠️ DO NOT DRILL"
        }
    }
    
    var emoji: String {
        switch self {
        case .safe:     return "✅"
        case .low:      return "🟡"
        case .moderate: return "🟠"
        case .high:     return "🔴"
        case .extreme:  return "⛔"
        }
    }
}

// MARK: - Anomaly Classification

/// Classification of what caused a magnetic anomaly
enum AnomalyClassification: String, CaseIterable {
    case none = "None"
    case nail = "Nail / Screw"
    case stud = "Metal Stud"
    case pipe = "Metal Pipe"
    case wiring = "Electrical Wiring"
    case rebar = "Rebar"
    case unknown = "Unknown Metal"
    
    /// Classify anomaly type based on deviation magnitude and signal characteristics
    /// - Parameters:
    ///   - deviation: Peak deviation from baseline in µT
    ///   - isOscillating: Whether the signal oscillates (AC current indicator)
    ///   - spreadWidth: How wide the anomaly is in readings (broad = pipe/stud, narrow = nail)
    static func classify(
        deviation: Double,
        isOscillating: Bool,
        spreadWidth: Int
    ) -> AnomalyClassification {
        // AC oscillation = likely electrical wiring
        if isOscillating && deviation > 5 {
            return .wiring
        }
        
        // Classify by magnitude and spread
        switch (deviation, spreadWidth) {
        case (..<5, _):
            return .none
        case (5..<20, ..<5):
            return .nail
        case (5..<20, 5...):
            return .stud
        case (20..<50, ..<8):
            return .nail
        case (20..<50, 8...):
            return .stud
        case (50..., ..<10):
            return .rebar
        case (50..., 10...):
            return .pipe
        default:
            return .unknown
        }
    }
}

// MARK: - Magnetic Reading (In-Memory)

/// Represents a single magnetometer reading during a scan
/// Not persisted — used during active scanning only
struct MagneticReading: Identifiable {
    let id = UUID()
    let timestamp: TimeInterval
    let x: Double      // µT
    let y: Double       // µT
    let z: Double       // µT
    let magnitude: Double  // total field strength in µT
    let deviation: Double  // deviation from baseline in µT
    
    /// Calculate magnitude from components
    static func calculateMagnitude(x: Double, y: Double, z: Double) -> Double {
        sqrt(x * x + y * y + z * z)
    }
}

// MARK: - Scan Status

/// Current state of the wall scanning process
enum ScanStatus: Equatable {
    case idle
    case calibrating
    case scanning
    case paused
    case complete
    
    var message: String {
        switch self {
        case .idle:        return "READY TO SCAN"
        case .calibrating: return "CALIBRATING..."
        case .scanning:    return "SCANNING WALL"
        case .paused:      return "SCAN PAUSED"
        case .complete:    return "SCAN COMPLETE"
        }
    }
}
