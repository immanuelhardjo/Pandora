//
//  ReeeeeModel.swift
//  Pandora - Reeeee MicroApp
//
//  Created by Immanuel Hardjo on 16/02/26.
//  Domain Model representing a single "yeet" record
//  Persisted with SwiftData
//

import Foundation
import SwiftData

// MARK: - Reeeee Domain Model

/// Domain model representing a single phone throw record
/// Persisted via SwiftData using the @Model macro
/// Contains physics calculations and metadata about the throw
@Model
final class ReeeeeModel: Identifiable {
    
    // MARK: - Persisted Properties
    
    /// Unique identifier for the record
    @Attribute(.unique) var id: UUID
    
    /// Total airtime in seconds
    var airtime: Double
    
    /// Timestamp of the throw
    var date: Date
    
    /// Peak altitude reached (meters), calculated from airtime
    var peakAltitude: Double
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        airtime: Double,
        date: Date
    ) {
        self.id = id
        self.airtime = airtime
        self.date = date
        self.peakAltitude = Self.calculatePeakAltitude(airtime: airtime)
    }
    
    // MARK: - Computed Properties
    
    /// Rank classification based on airtime performance
    var rank: String {
        switch airtime {
        case ..<0.5: return "Weak Toss"
        case 0.5..<1.0: return "Solid Send"
        case 1.0..<1.5: return "Lunar Bound"
        default: return "God Tier"
        }
    }
    
    /// Initial velocity required for this airtime (m/s)
    var initialVelocity: Double {
        let gravity = 9.80665
        let timeInAscent = airtime / 2
        return gravity * timeInAscent
    }
    
    /// User-friendly date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Physics Calculation
    
    /// Calculate peak altitude based on airtime using kinematic equations
    /// Formula: h = 0.5 * g * t²  (where t is half the airtime - time to peak)
    static func calculatePeakAltitude(airtime: Double) -> Double {
        let gravity = 9.80665 // m/s²
        let timeInAscent = airtime / 2
        return 0.5 * gravity * pow(timeInAscent, 2)
    }
}
