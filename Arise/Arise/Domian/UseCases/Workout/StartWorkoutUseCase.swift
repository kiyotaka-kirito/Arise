//
//  StartWorkoutUseCase.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation
import RxSwift

// MARK: - Protocol
protocol StartWorkoutUseCaseProtocol {
    func execute(type: WorkoutType, userId: String) -> Single<WorkoutSession>
}

// MARK: - UseCase
final class StartWorkoutUseCase: StartWorkoutUseCaseProtocol {
    
    // Dependencies
    private let workoutRepository: WorkoutRepositoryProtocol
    private let locationService: LocationServiceProtocol
    private let disposeBag = DisposeBag()
    
    // Init
    init(workoutRepository: WorkoutRepositoryProtocol, locationService: LocationServiceProtocol) {
        self.workoutRepository = workoutRepository
        self.locationService = locationService
    }
    
    // Execute
    func execute(type: WorkoutType, userId: String) -> RxSwift.Single<WorkoutSession> {
        return workoutRepository
            .fetchActiveSession(for: userId)
            .take(1)
            .asSingle()
            .flatMap { [weak self] activeSession -> Single<WorkoutSession> in
                guard let self = self else {
                    return .error(WorkoutError.unknown)
                }
                
                if activeSession != nil {
                    return .error(WorkoutError.sessionAlreadyActive)
                }
                
                return self.createAndSaveSession(type: type, userId: userId)
            }
    }
    
    // Helpers
    private func createAndSaveSession(type: WorkoutType, userId: String) -> Single<WorkoutSession> {
        let newSession = WorkoutSession(userId: userId, type: type, status: .active, startTime: Date())
        return workoutRepository
            .createWorkoutSession(newSession)
            .andThen(startLocationIfNeeded(for: type))
            .andThen(Single.just(newSession))
            
    }
    
    private func startLocationIfNeeded(for type: WorkoutType) -> Completable {
        guard type.requiresGPSTracking else { return .empty() }
        locationService.requestAlwaysAuthorization()
        return .empty()
    }
    
}

// MARK: - Error
enum WorkoutError: LocalizedError {
    case sessionAlreadyActive
    case sessionNotFound
    case saveFailed
    case locationPermissionDenied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .sessionAlreadyActive:     return "A workout is already in progress. Please finish it first."
        case .sessionNotFound:          return "Workout session could not be found."
        case .saveFailed:               return "Failed to save workout. Please try again."
        case .locationPermissionDenied: return "Location access is needed for route tracking."
        case .unknown:                  return "Something went wrong. Please try again."
        }
    }
}
