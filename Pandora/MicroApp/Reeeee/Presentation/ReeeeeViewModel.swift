//
//  ReeeeeViewModel.swift
//  Pandora - Reeeee MicroApp
//
//  Created by Immanuel Hardjo on 16/02/26.
//  Enhanced with Clean Architecture and dependency injection
//

import Foundation
import CoreMotion
import Observation
import AVFoundation
import SwiftData

// MARK: - Motion Service Protocol

/// Protocol abstracting accelerometer access for testability
/// Wraps CMMotionManager so tests can inject a mock
protocol MotionServiceProtocol: AnyObject {
    var isAccelerometerAvailable: Bool { get }
    var accelerometerUpdateInterval: TimeInterval { get set }
    
    func startAccelerometerUpdates(
        to queue: OperationQueue,
        withHandler handler: @escaping (CMAccelerometerData?, Error?) -> Void
    )
    func stopAccelerometerUpdates()
}

// MARK: - CMMotionManager Conformance

/// CMMotionManager already satisfies the protocol — no wrapper needed
extension CMMotionManager: MotionServiceProtocol {}

// MARK: - ViewModel Protocol

/// Protocol defining ReeeeeViewModel interface for testability
protocol ReeeeeViewModelProtocol: AnyObject {
    var currentAirtime: Double { get }
    var status: YeetStatus { get }
    var history: [ReeeeeModel] { get }
    var highScore: Double { get }
    
    func startMonitoring()
    func stopMonitoring()
    func clearHistory()
}

// MARK: - Reeeee ViewModel

/// ViewModel managing the Reeeee MicroApp state and orchestrating business logic
/// Follows MVVM pattern with dependency injection
/// Uses SwiftDataRepository for persistence
@Observable
final class ReeeeeViewModel: ReeeeeViewModelProtocol {
    
    // MARK: - Dependencies
    
    private let repository: AnyRepository<ReeeeeModel>
    private let motionManager: MotionServiceProtocol
    private let audioService: AudioServiceProtocol
    
    // MARK: - State
    
    var currentAirtime: Double = 0.0
    var status: YeetStatus = .ready
    var history: [ReeeeeModel] = []
    
    // MARK: - Private Properties
    
    private var airtimeTimer: Timer?
    private var startTime: Date?
    
    // MARK: - Constants
    
    private enum MotionThreshold {
        static let freefall: Double = 0.15
        static let impact: Double = 1.3
        static let updateInterval: TimeInterval = 0.01
    }
    
    // MARK: - Computed Properties
    
    var highScore: Double {
        history.map { $0.airtime }.max() ?? 0.0
    }
    
    // MARK: - Initialization
    
    init(
        repository: AnyRepository<ReeeeeModel>,
        motionManager: MotionServiceProtocol = CMMotionManager(),
        audioService: AudioServiceProtocol = AudioService()
    ) {
        self.repository = repository
        self.motionManager = motionManager
        self.audioService = audioService
        
        // Load initial data
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else {
            print("⚠️ Accelerometer not available")
            return
        }
        
        motionManager.accelerometerUpdateInterval = MotionThreshold.updateInterval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let acceleration = data?.acceleration else { return }
            self.processAcceleration(acceleration)
        }
    }
    
    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
        stopAirtimeTracking()
        audioService.stop()
    }
    
    func clearHistory() {
        do {
            try repository.deleteAll()
            history.removeAll()
            print("✅ History cleared")
        } catch {
            print("⚠️ Failed to clear history: \(error)")
        }
    }
    
    // MARK: - Motion Processing
    
    private func processAcceleration(_ acceleration: CMAcceleration) {
        let totalG = calculateGForce(from: acceleration)
        
        if status != .inAir && totalG < MotionThreshold.freefall {
            handleFreefallDetected()
        } else if status == .inAir && totalG > MotionThreshold.impact {
            handleImpactDetected()
        }
    }
    
    private func calculateGForce(from acceleration: CMAcceleration) -> Double {
        sqrt(
            pow(acceleration.x, 2) +
            pow(acceleration.y, 2) +
            pow(acceleration.z, 2)
        )
    }
    
    // MARK: - Yeet Lifecycle
    
    private func handleFreefallDetected() {
        status = .inAir
        startAirtimeTracking()
        audioService.play()
    }
    
    private func handleImpactDetected() {
        stopAirtimeTracking()
        audioService.stop()
        status = .landed
        
        // Save the record using repository
        saveRecord()
        
        scheduleReset()
    }
    
    private func scheduleReset() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.status == .landed else { return }
            self.status = .ready
            self.currentAirtime = 0.0
        }
    }
    
    // MARK: - Airtime Tracking
    
    private func startAirtimeTracking() {
        startTime = Date()
        airtimeTimer = Timer.scheduledTimer(
            withTimeInterval: MotionThreshold.updateInterval,
            repeats: true
        ) { [weak self] _ in
            self?.updateAirtime()
        }
    }
    
    private func stopAirtimeTracking() {
        airtimeTimer?.invalidate()
        airtimeTimer = nil
        startTime = nil
    }
    
    private func updateAirtime() {
        guard let startTime = startTime else { return }
        currentAirtime = Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Data Operations
    
    private func saveRecord() {
        let record = ReeeeeModel(
            airtime: currentAirtime,
            date: Date()
        )
        
        do {
            try repository.save(record)
            history.insert(record, at: 0)
            print("✅ Record saved: \(String(format: "%.2fs", record.airtime))")
        } catch {
            print("⚠️ Failed to save record: \(error)")
        }
    }
    
    private func loadHistory() {
        do {
            history = try repository.fetchAll()
            print("✅ Loaded \(history.count) records")
        } catch {
            print("⚠️ Failed to load history: \(error)")
            history = []
        }
    }
}

// MARK: - YeetStatus

/// Enum representing the current state of the yeet tracking
enum YeetStatus: Equatable {
    case ready
    case inAir
    case landed
    
    var message: String {
        switch self {
        case .ready: return "WAITING FOR SEND"
        case .inAir: return "FLYING..."
        case .landed: return "RECOVERED"
        }
    }
}

// MARK: - Audio Service Protocol

/// Protocol for audio playback abstraction
protocol AudioServiceProtocol {
    func play()
    func stop()
}

// MARK: - Audio Service Implementation

/// Concrete audio service implementation
final class AudioService: AudioServiceProtocol {
    
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        setupAudio()
    }
    
    func play() {
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
    
    func stop() {
        audioPlayer?.stop()
    }
    
    private func setupAudio() {
        guard let audioURL = Bundle.main.url(forResource: "Reeee", withExtension: "m4a") else {
            print("⚠️ Reeee.m4a not found in bundle")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Failed to setup audio: \(error.localizedDescription)")
        }
    }
}

// MARK: - ViewModel Factory

/// Factory for creating ReeeeeViewModel instances with proper dependencies
enum ReeeeeViewModelFactory {
    
    @MainActor
    static func makeViewModel(
        repository: AnyRepository<ReeeeeModel>
    ) -> ReeeeeViewModel {
        ReeeeeViewModel(
            repository: repository,
            motionManager: CMMotionManager(),
            audioService: AudioService()
        )
    }
    
    /// Create ViewModel with custom dependencies (useful for testing)
    @MainActor
    static func makeViewModel(
        repository: AnyRepository<ReeeeeModel>,
        motionManager: MotionServiceProtocol,
        audioService: AudioServiceProtocol
    ) -> ReeeeeViewModel {
        ReeeeeViewModel(
            repository: repository,
            motionManager: motionManager,
            audioService: audioService
        )
    }
}
