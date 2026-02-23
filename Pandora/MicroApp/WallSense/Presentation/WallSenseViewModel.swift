//
//  WallSenseViewModel.swift
//  Pandora - WallSense MicroApp
//
//  ViewModel managing WallSense scanning state, magnetometer input,
//  calibration, anomaly classification, and scan history
//

import Foundation
import CoreMotion
import Observation
import SwiftData
import UIKit

// MARK: - Magnetometer Service Protocol

/// Protocol abstracting magnetometer access for testability
/// Wraps CMMagnetometer so tests can inject a mock
protocol MagnetometerServiceProtocol: AnyObject {
    var isMagnetometerAvailable: Bool { get }
    var magnetometerUpdateInterval: TimeInterval { get set }
    
    func startMagnetometerUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping (CMMagnetometerData?, Error?) -> Void
    )
    func stopMagnetometerUpdates()
}

// MARK: - CMMotionManager Conformance

/// CMMotionManager already satisfies the protocol — no wrapper needed
extension CMMotionManager: MagnetometerServiceProtocol {}

// MARK: - Haptic Service Protocol

/// Protocol abstracting haptic feedback for testability
protocol HapticServiceProtocol {
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle)
    func notification(type: UINotificationFeedbackGenerator.FeedbackType)
}

// MARK: - Haptic Service Implementation

/// Concrete haptic service using UIKit feedback generators
final class HapticService: HapticServiceProtocol {
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

// MARK: - ViewModel Protocol

/// Protocol defining WallSenseViewModel interface for testability
protocol WallSenseViewModelProtocol: AnyObject {
    var status: ScanStatus { get }
    var currentDeviation: Double { get }
    var currentThreatLevel: ThreatLevel { get }
    var readingCount: Int { get }
    var history: [WallScanModel] { get }
    
    func startCalibration()
    func startScanning()
    func stopScanning()
    func saveScan(locationName: String)
    func clearHistory()
}

// MARK: - WallSense ViewModel

/// ViewModel managing the WallSense MicroApp state and orchestrating business logic
/// Handles magnetometer input, calibration, real-time anomaly detection, and scan persistence
@Observable
final class WallSenseViewModel: WallSenseViewModelProtocol {
    
    // MARK: - Dependencies
    
    private let repository: AnyRepository<WallScanModel>
    private let magnetometer: MagnetometerServiceProtocol
    private let hapticService: HapticServiceProtocol
    
    // MARK: - State
    
    var status: ScanStatus = .idle
    var currentDeviation: Double = 0.0
    var currentMagnitude: Double = 0.0
    var currentThreatLevel: ThreatLevel = .safe
    var currentClassification: AnomalyClassification = .none
    var history: [WallScanModel] = []
    var peakDeviation: Double = 0.0
    var isOscillating: Bool = false
    var readingCount: Int = 0
    
    // MARK: - Per-Axis State
    
    /// Current per-axis deviations from baseline (µT)
    /// Positive X = metal is to the RIGHT, Negative X = metal is to the LEFT
    /// Positive Y = metal is ABOVE, Negative Y = metal is BELOW
    /// Z = depth axis (perpendicular to phone screen / wall surface)
    var currentXDeviation: Double = 0.0
    var currentYDeviation: Double = 0.0
    var currentZDeviation: Double = 0.0
    
    /// Directional pull angle (radians, 0 = right, π/2 = up)
    var directionalAngle: Double = 0.0
    
    /// Strength of directional pull (0..1, higher = stronger directional signal)
    var directionalStrength: Double = 0.0
    
    // MARK: - Calibration State
    
    var baselineMagnitude: Double = 0.0
    var baselineX: Double = 0.0
    var baselineY: Double = 0.0
    var baselineZ: Double = 0.0
    var noiseFloor: Double = 2.0  // Default 2 µT noise floor
    var calibrationProgress: Double = 0.0
    
    // MARK: - Private Properties
    
    private var calibrationReadings: [MagneticReading] = []
    private var scanStartTime: Date?
    private var lastHapticThreat: ThreatLevel = .safe
    private var anomalyCount: Int = 0
    
    /// Running deviation sum for computing average at save time (avoids storing full array)
    private var deviationSum: Double = 0.0
    
    /// Previous deviation — used for anomaly edge-detection without array access
    private var previousDeviation: Double = 0.0
    
    /// Ring buffer of recent deviations for oscillation detection (fixed size, no UUID allocations)
    private var recentDeviations: [Double] = []
    
    /// Count of consecutive readings above noise floor — used for spread/classification
    private var aboveNoiseStreak: Int = 0
    
    // MARK: - Constants
    
    private enum Config {
        static let updateInterval: TimeInterval = 1.0 / 5.0   // 5 Hz
        static let calibrationDuration: Int = 15   // 3 seconds × 5 Hz
        static let maxReadings: Int = 50           // 10 seconds of readings
        static let oscillationWindow: Int = 3      // ~0.6 second window for oscillation
    }
    
    // MARK: - Initialization
    
    init(
        repository: AnyRepository<WallScanModel>,
        magnetometer: MagnetometerServiceProtocol = CMMotionManager(),
        hapticService: HapticServiceProtocol = HapticService()
    ) {
        self.repository = repository
        self.magnetometer = magnetometer
        self.hapticService = hapticService
        
        loadHistory()
    }
    
    // MARK: - Calibration
    
    /// Begin baseline calibration — hold phone in the air away from any metal
    func startCalibration() {
        guard magnetometer.isMagnetometerAvailable else {
            print("⚠️ Magnetometer not available")
            return
        }
        
        status = .calibrating
        calibrationReadings.removeAll()
        calibrationProgress = 0.0
        
        magnetometer.magnetometerUpdateInterval = Config.updateInterval
        magnetometer.startMagnetometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let field = data?.magneticField else { return }
            self.processCalibrationReading(x: field.x, y: field.y, z: field.z)
        }
    }
    
    private func processCalibrationReading(x: Double, y: Double, z: Double) {
        let magnitude = MagneticReading.calculateMagnitude(x: x, y: y, z: z)
        let reading = MagneticReading(
            timestamp: Date().timeIntervalSince1970,
            x: x, y: y, z: z,
            magnitude: magnitude,
            deviation: 0
        )
        
        calibrationReadings.append(reading)
        calibrationProgress = Double(calibrationReadings.count) / Double(Config.calibrationDuration)
        currentMagnitude = magnitude
        
        if calibrationReadings.count >= Config.calibrationDuration {
            finishCalibration()
        }
    }
    
    private func finishCalibration() {
        magnetometer.stopMagnetometerUpdates()
        
        let calibrateUseCase = CalibrateBaselineUseCase()
        do {
            let result = try calibrateUseCase.execute(
                .init(readings: calibrationReadings)
            )
            baselineMagnitude = result.baselineMagnitude
            baselineX = result.baselineX
            baselineY = result.baselineY
            baselineZ = result.baselineZ
            noiseFloor = max(result.noiseFloor, 2.0)  // Minimum 2 µT noise floor
            calibrationProgress = 1.0
            status = .idle
            
            hapticService.notification(type: .success)
            print("✅ Calibrated: baseline=\(String(format: "%.1f", baselineMagnitude)) µT (X:\(String(format: "%.1f", baselineX)), Y:\(String(format: "%.1f", baselineY)), Z:\(String(format: "%.1f", baselineZ))), noise=\(String(format: "%.1f", noiseFloor)) µT")
        } catch {
            print("⚠️ Calibration failed: \(error)")
            status = .idle
            hapticService.notification(type: .error)
        }
    }
    
    // MARK: - Scanning
    
    /// Begin wall scanning after calibration
    func startScanning() {
        guard magnetometer.isMagnetometerAvailable else {
            print("⚠️ Magnetometer not available")
            return
        }
        guard baselineMagnitude > 0 else {
            print("⚠️ Must calibrate before scanning")
            startCalibration()
            return
        }
        
        status = .scanning
        readingCount = 0
        peakDeviation = 0.0
        anomalyCount = 0
        deviationSum = 0.0
        previousDeviation = 0.0
        recentDeviations.removeAll()
        aboveNoiseStreak = 0
        currentClassification = .none
        scanStartTime = Date()
        
        magnetometer.magnetometerUpdateInterval = Config.updateInterval
        magnetometer.startMagnetometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let field = data?.magneticField else { return }
            self.processScanReading(x: field.x, y: field.y, z: field.z)
        }
    }
    
    /// Stop the current scan
    func stopScanning() {
        magnetometer.stopMagnetometerUpdates()
        
        if status == .scanning {
            status = .complete
            classifyCurrentReadings()
        } else {
            status = .idle
        }
    }
    
    private func processScanReading(x: Double, y: Double, z: Double) {
        let magnitude = MagneticReading.calculateMagnitude(x: x, y: y, z: z)
        let deviation = abs(magnitude - baselineMagnitude)
        
        readingCount += 1
        deviationSum += deviation
        
        // Update live state (batch observable property writes)
        currentDeviation = deviation
        currentMagnitude = magnitude
        
        // Per-axis tracking
        currentXDeviation = x - baselineX
        currentYDeviation = y - baselineY
        currentZDeviation = z - baselineZ
        
        // Directional indicator from X/Y lateral vector
        let lateralMagnitude = sqrt(currentXDeviation * currentXDeviation + currentYDeviation * currentYDeviation)
        directionalAngle = atan2(currentYDeviation, currentXDeviation)
        directionalStrength = min(lateralMagnitude / max(currentDeviation, 1.0), 1.0)
        
        // Peak tracking
        if deviation > peakDeviation {
            peakDeviation = deviation
        }
        
        // Threat level — only fire haptics on change
        let newThreat = ThreatLevel.classify(deviation: deviation)
        if newThreat != currentThreatLevel {
            currentThreatLevel = newThreat
            provideHapticFeedback(for: newThreat)
        }
        
        // Anomaly edge-detection: count transitions from below→above noise floor
        if deviation > noiseFloor {
            aboveNoiseStreak += 1
            if previousDeviation <= noiseFloor {
                anomalyCount += 1
            }
        } else {
            aboveNoiseStreak = 0
        }
        previousDeviation = deviation
        
        // Ring buffer for oscillation detection (fixed capacity, no UUID allocations)
        recentDeviations.append(deviation)
        if recentDeviations.count > Config.oscillationWindow {
            recentDeviations.removeFirst()
        }
        isOscillating = detectOscillation(in: recentDeviations)
        
        // Live classification — uses scalars only, no array scanning
        currentClassification = AnomalyClassification.classify(
            deviation: deviation,
            isOscillating: isOscillating,
            spreadWidth: aboveNoiseStreak
        )
    }
    
    private func detectOscillation(in window: [Double]) -> Bool {
        guard window.count > 4 else { return false }
        
        var signChanges = 0
        var previousDelta: Double?
        
        for i in 1..<window.count {
            let delta = window[i] - window[i - 1]
            if let prev = previousDelta, prev * delta < 0 {
                signChanges += 1
            }
            previousDelta = delta
        }
        
        let ratio = Double(signChanges) / Double(window.count - 2)
        return ratio > 0.3
    }
    
    private func classifyCurrentReadings() {
        guard readingCount > 0 else { return }
        
        // Final classification uses accumulated scalars — no array needed
        currentClassification = AnomalyClassification.classify(
            deviation: peakDeviation,
            isOscillating: isOscillating,
            spreadWidth: aboveNoiseStreak
        )
        currentThreatLevel = ThreatLevel.classify(deviation: peakDeviation)
    }
    
    // MARK: - Haptic Feedback
    
    private func provideHapticFeedback(for threat: ThreatLevel) {
        // Only fire haptics on escalation
        guard threat.severity > lastHapticThreat.severity else { return }
        lastHapticThreat = threat
        
        switch threat {
        case .safe:
            break
        case .low:
            hapticService.impact(style: .light)
        case .moderate:
            hapticService.impact(style: .medium)
        case .high:
            hapticService.impact(style: .heavy)
        case .extreme:
            hapticService.notification(type: .error)
        }
        
        // Reset after 1 second to allow re-firing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.lastHapticThreat = .safe
        }
    }
    
    // MARK: - Data Operations
    
    /// Save the current scan to history
    func saveScan(locationName: String) {
        guard status == .complete, readingCount > 0 else { return }
        
        let avgDeviation = deviationSum / Double(readingCount)
        let duration = scanStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        let scan = WallScanModel(
            locationName: locationName.isEmpty ? "Untitled Scan" : locationName,
            peakDeviation: peakDeviation,
            averageDeviation: avgDeviation,
            baselineMagnitude: baselineMagnitude,
            anomalyCount: anomalyCount,
            primaryClassification: currentClassification.rawValue,
            threatLevelRaw: currentThreatLevel.rawValue,
            scanDuration: duration
        )
        
        do {
            try repository.save(scan)
            history.insert(scan, at: 0)
            hapticService.notification(type: .success)
            print("✅ Scan saved: \(scan.locationName)")
        } catch {
            print("⚠️ Failed to save scan: \(error)")
        }
        
        resetScan()
    }
    
    func clearHistory() {
        do {
            try repository.deleteAll()
            history.removeAll()
            hapticService.notification(type: .warning)
            print("✅ Scan history cleared")
        } catch {
            print("⚠️ Failed to clear history: \(error)")
        }
    }
    
    func resetScan() {
        readingCount = 0
        currentDeviation = 0
        peakDeviation = 0
        anomalyCount = 0
        deviationSum = 0
        previousDeviation = 0
        aboveNoiseStreak = 0
        recentDeviations.removeAll()
        currentThreatLevel = .safe
        currentClassification = .none
        isOscillating = false
        currentXDeviation = 0
        currentYDeviation = 0
        currentZDeviation = 0
        directionalAngle = 0
        directionalStrength = 0
        status = .idle
    }
    
    private func loadHistory() {
        do {
            history = try repository.fetchAll()
                .sorted { $0.date > $1.date }
            print("✅ Loaded \(history.count) wall scans")
        } catch {
            print("⚠️ Failed to load scan history: \(error)")
            history = []
        }
    }
}

// MARK: - ThreatLevel Severity Extension

extension ThreatLevel {
    /// Numeric severity for comparison
    var severity: Int {
        switch self {
        case .safe:     return 0
        case .low:      return 1
        case .moderate: return 2
        case .high:     return 3
        case .extreme:  return 4
        }
    }
}

// MARK: - ViewModel Factory

/// Factory for creating WallSenseViewModel instances with proper dependencies
enum WallSenseViewModelFactory {
    
    @MainActor
    static func makeViewModel(
        repository: AnyRepository<WallScanModel>
    ) -> WallSenseViewModel {
        WallSenseViewModel(
            repository: repository,
            magnetometer: CMMotionManager(),
            hapticService: HapticService()
        )
    }
    
    /// Create ViewModel with custom dependencies (useful for testing)
    @MainActor
    static func makeViewModel(
        repository: AnyRepository<WallScanModel>,
        magnetometer: MagnetometerServiceProtocol,
        hapticService: HapticServiceProtocol
    ) -> WallSenseViewModel {
        WallSenseViewModel(
            repository: repository,
            magnetometer: magnetometer,
            hapticService: hapticService
        )
    }
}
