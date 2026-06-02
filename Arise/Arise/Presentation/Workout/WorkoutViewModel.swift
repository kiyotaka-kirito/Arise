//
//  WorkoutViewModel.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RxSwift

// MARK: - WorkoutViewModel
final class WorkoutViewModel {
    
    // MARK: - Dependencies
    private let startWorkoutUseCase: StartWorkoutUseCaseProtocol
    private let stopWorkoutUseCase: StopWorkoutUseCaseProtocol
    private let locationService: LocationServiceProtocol
    private let bluetoothService: BluetoothServiceProtocol
    
    // MARK: - Outputs
    let currentSession = BehaviorSubject<WorkoutSession?>(value: nil)
    let isTracking = BehaviorSubject<Bool>(value: false)
    let elapsedTime = BehaviorSubject<String>(value: "00:00")
    let currentHeartRate = BehaviorSubject<Double>(value: 0)
    let errorMessage = PublishSubject<String>()
    
    // MARK: - Memory Management
    private let disposeBag = DisposeBag()
    
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
    }
    
    // MARK: - Inputs
    func startWorkout(type: WorkoutType, userId: String) {
        
    }
    
    func stopWorkout() {
        
    }
    
}
