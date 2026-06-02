//
//  FetchWorkoutHistoryUseCase.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation
import RxSwift

// MARK: - Protocol
protocol FetchWorkoutHistoryUseCaseProtocol {
    func execute(userId: String, limit: Int) -> Observable<[WorkoutSession]>
}

// MARK: - UseCase
final class FetchWorkoutHistoryUseCase: FetchWorkoutHistoryUseCaseProtocol {
    
    // Dependencies
    private let workoutRepository: WorkoutRepositoryProtocol
    
    // Init
    init(workoutRepository: WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }
    
    // Execute
    func execute(userId: String, limit: Int = 20) -> Observable<[WorkoutSession]> {
        workoutRepository
            .fetchWorkoutHistory(for: userId, limit: limit)
            .map { session in
                session.filter { $0.status == .completed }
            }
    }
    
}

