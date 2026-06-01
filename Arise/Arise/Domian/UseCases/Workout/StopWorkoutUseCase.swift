//
//  StopWorkoutUseCase.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation
import RxSwift

// MARK: - Protocol
protocol StopWorkoutUseCaseProtocol {
    func execute(session: WorkoutSession) -> Single<WorkoutSession>
}

// MARK: - UseCase
final class StopWorkoutUseCase: StopWorkoutUseCaseProtocol {
    
    // Dependencies
    private let workoutRepository: WorkoutRepositoryProtocol
    private let locationService: LocationServiceProtocol
    
    // Init
    init(workoutRepository: WorkoutRepositoryProtocol, locationService: LocationServiceProtocol) {
        self.workoutRepository = workoutRepository
        self.locationService = locationService
    }
    
    // Execute
    func execute(session: WorkoutSession) -> Single<WorkoutSession> {
        guard session.status == .active || session.status == .paused else {
            return .error(WorkoutError.sessionNotFound)
        }
        
        guard session.isValid else { return cancelSession(session) }
        
        let finalSession = buildFinalSession(from: session)
        locationService.stopTracking()
        
        return workoutRepository
            .completeWorkoutSession(finalSession)
            .andThen(Single.just(finalSession))
    }
    
    // Helpers
    private func buildFinalSession(from session: WorkoutSession) -> WorkoutSession {
        var completed = session
        
        completed.endTime = Date()
        completed.status = .completed
        
        let hrSamples = session.heartRateSamples.map { $0.value }
        if !hrSamples.isEmpty {
            completed.averageHeartRate = (hrSamples.reduce(0, +) / Double(hrSamples.count)).rounded(toPlaces: 1)
            completed.maxHeartRate = hrSamples.max()
        }
        
        let speeds = session.gpsRoute.map { $0.speed }.filter { $0 > 0 }
        if !speeds.isEmpty {
            completed.averageSpeedMps = (speeds.reduce(0, +) / Double(speeds.count)).rounded(toPlaces: 2)
        }
        
        return completed
    }
    
    private func cancelSession(_ session: WorkoutSession) -> Single<WorkoutSession> {
        var cancelled = session
        cancelled.status = .cancelled
        
        return workoutRepository
            .deleteWorkoutSession(by: session.id)
            .andThen(Single.just(cancelled))
    }
    
}
