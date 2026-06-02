//
//  WorkoutViewModel.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftUI

// MARK: - WorkoutViewModel
final class WorkoutViewModel {
    
    // MARK: - Dependencies
    private let startWorkoutUseCase: StartWorkoutUseCaseProtocol
    private let stopWorkoutUseCase: StopWorkoutUseCaseProtocol
    private let locationService: LocationServiceProtocol
    private let bluetoothService: BluetoothServiceProtocol
    
    // MARK: - Outputs
    let currentSession = BehaviorRelay<WorkoutSession?>(value: nil)
    let isTracking = BehaviorRelay<Bool>(value: false)
    let isPaused = BehaviorRelay<Bool>(value: false)
    let elapsedTime = BehaviorRelay<String>(value: "00:00")
    let currentHeartRate = BehaviorRelay<Double>(value: 0)
    let currentSpeed = BehaviorRelay<Double>(value: 0)
    let currentDistance = BehaviorRelay<Double>(value: 0)
    let gpsRoute = BehaviorRelay<[GPSCoordinate]>(value: [])
    let errorMessage = PublishRelay<String>()
    let workoutCompleted = PublishRelay<WorkoutSession>()
    
    // MARK: - State
    private var activeSessionId: String?
    private var workoutStartTime: Date?
    private var connectedDeviceId: String?
    
    // MARK: - Memory Management
    private let disposeBag = DisposeBag()
    private var workoutBag = DisposeBag()
    
    // MARK: - Init
    init(
        startWorkoutUseCase: StartWorkoutUseCaseProtocol,
        stopWorkoutUseCase: StopWorkoutUseCaseProtocol,
        locationService: LocationServiceProtocol,
        bluetoothService: BluetoothServiceProtocol
    ) {
        self.startWorkoutUseCase = startWorkoutUseCase
        self.stopWorkoutUseCase = stopWorkoutUseCase
        self.locationService = locationService
        self.bluetoothService = bluetoothService
        setupBluetoothDeviceObserver()
    }
    
    // MARK: - Inputs
    func startWorkout(type: WorkoutType, userId: String) {
        workoutBag = DisposeBag()
        
        startWorkoutUseCase.execute(type: type, userId: userId)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] session in
                    guard let self = self else { return }
                    self.currentSession.accept(session)
                    self.activeSessionId = session.id
                    self.workoutStartTime = session.startTime
                    self.isTracking.accept(true)
                    self.isPaused.accept(false)
                    
                    // Start all three live streams
                    self.startTimer()
                    if type.requiresGPSTracking {
                        self.startLocationTracking()
                    }
                    self.startHeartRateMonitoring()
                },
                onFailure: { [weak self] error in
                    self?.errorMessage.accept(error.localizedDescription)
                }
            )
            .disposed(by: workoutBag)
    }
    
    func pauseWorkout() {
        guard isTracking.value, !isPaused.value else { return }
        isPaused.accept(true)
        locationService.pauseTracking()
    }
    
    func resumeWorkout() {
        guard isPaused.value else { return }
        isPaused.accept(false)
        locationService.resumeTracking()
    }
    
    func stopWorkout() {
        guard let session = currentSession.value else { return }
        
        var finalSession = session
        finalSession.endTime = Date()
        finalSession.totalDistanceMeters = currentDistance.value
        finalSession.gpsRoute = gpsRoute.value
        
        stopWorkoutUseCase.execute(session: finalSession)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] completedSession in
                    guard let self = self else { return }
                    self.cleanupWorkout()
                    self.workoutCompleted.accept(completedSession)
                },
                onFailure: { [weak self] error in
                    self?.errorMessage.accept(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }
    
    // MARK: - Timer Stream
    private func startTimer() {
        Observable<Int>.interval(.seconds(1), scheduler: ConcurrentDispatchQueueScheduler(qos: .utility))
            .filter { [weak self] _ in
                !(self?.isPaused.value ?? false)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] _ in
                    guard let self = self,
                          let startTime = self.workoutStartTime
                    else { return }
                    
                    // Calculate real elapsed time from start
                    let elapsed = Date().timeIntervalSince(startTime)
                    self.elapsedTime.accept(self.formatDuration(elapsed))
                }
            )
            .disposed(by: workoutBag)
    }
    
    // MARK: - GPS Stream
    private func startLocationTracking() {
        locationService.startTracking()
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] coordinate in
                    guard let self = self else { return }
                    
                    // Append new coordinate to route
                    var route = self.gpsRoute.value
                    route.append(coordinate)
                    self.gpsRoute.accept(route)
                    
                    // Update speed display
                    self.currentSpeed.accept(coordinate.speed)
                    
                    // Calculate total distance from GPS points
                    self.currentDistance.accept(self.calculateTotalDistance(route))
                }
            )
            .disposed(by: workoutBag)
    }
    
    // MARK: - Heart Rate Stream
    private func startHeartRateMonitoring() {
        guard let deviceId = connectedDeviceId else { return }
        
        bluetoothService.observeHeartRate(from: deviceId)
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] metric in
                    self?.currentHeartRate.accept(metric.value)
                    
                    // Append HR sample to session
                    if var session = self?.currentSession.value {
                        session.heartRateSamples.append(metric)
                        self?.currentSession.accept(session)
                    }
                }
            )
            .disposed(by: workoutBag)
    }
    
    // MARK: - Bluetooth Device Observer
    private func setupBluetoothDeviceObserver() {
        bluetoothService.connectedDevices
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] devices in
                    self?.connectedDeviceId = devices.first?.id
                }
            )
            .disposed(by: disposeBag)
    }
    
    // MARK: - Cleanup
    private func cleanupWorkout() {
        workoutBag = DisposeBag()
        locationService.stopTracking()
        isTracking.accept(false)
        isPaused.accept(false)
        currentDistance.accept(0)
        currentSpeed.accept(0)
        currentHeartRate.accept(0)
        gpsRoute.accept([])
        elapsedTime.accept("00:00")
        currentSession.accept(nil)
        workoutStartTime = nil
    }
    
    // MARK: - Helpers
    private func calculateTotalDistance(_ route: [GPSCoordinate]) -> Double {
        guard route.count >= 2 else { return 0}
        
        var total: Double = 0
        for i in 1..<route.count {
            total += haversineDistance(from: route[i-1], to: route[i])
        }
        return total
    }
    
    private func haversineDistance(from start: GPSCoordinate, to end: GPSCoordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLat = (end.latitude - start.latitude) * .pi / 180
        let deltaLon = (end.longitude - start.longitude) * .pi / 180
        
        let a = sin(deltaLat/2) * sin(deltaLat/2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon/2) * sin(deltaLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return earthRadiusMeters * c
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let total   = Int(interval)
        let hours   = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Computed Display Helpers
    var speedDisplay: String {
        let kmh = currentSpeed.value * 3.6
        return String(format: "%.1f km/h", kmh)
    }
    
    var distanceDisplay: String {
        let meters = currentDistance.value
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }
    
    var heartRateZone: HeartRateZone {
        HeartRateZone(bpm: currentHeartRate.value)
    }
}

// MARK: - HeartRateZone
enum HeartRateZone {
    case rest       // <60
    case fatBurn    // 60-100
    case cardio     // 100-140
    case peak       // 140-170
    case maximum    // 170+
    
    init(bpm: Double) {
        switch bpm {
        case ..<60:     self = .rest
        case ..<100:    self = .fatBurn
        case ..<140:    self = .cardio
        case ..<170:    self = .peak
        default:        self = .maximum
        }
    }
    
    var displayName: String {
        switch self {
        case .rest:     return "Rest"
        case .fatBurn:  return "Fat Burn"
        case .cardio:   return "Cardio"
        case .peak:     return "Peak"
        case .maximum:  return "Maximum"
        }
    }
    
    var color: String {
        switch self {
        case .rest:     return "zoneBlue"
        case .fatBurn:  return "zoneGreen"
        case .cardio:   return "zoneYellow"
        case .peak:     return "zoneOrange"
        case .maximum:  return "zoneRed"
        }
    }
    
    var swiftUIColor: any ShapeStyle {
        switch self {
        case .rest:     return Color.blue
        case .fatBurn:  return Color.green
        case .cardio:   return Color.yellow
        case .peak:     return Color.orange
        case .maximum:  return Color.red
        }
    }
}
