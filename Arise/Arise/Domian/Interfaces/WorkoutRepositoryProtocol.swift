//
//  WorkoutRepositoryProtocol.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation
import RxSwift

// MARK: - WorkoutRepositoryProtocol
protocol WorkoutRepositoryProtocol {
    
    // Active Session Management
    func createWorkoutSession(_ session: WorkoutSession) -> Completable
    func updateWorkoutSession(_ session: WorkoutSession) -> Completable
    func completeWorkoutSession(_ session: WorkoutSession) -> Completable
    
    // Fetch
    func fetchWorkoutHistory(for userId: String, limit: Int) -> Observable<[WorkoutSession]>
    func fetchWorkouts(for userId: String, type: WorkType, in dateRange: DateRange) -> Observable<[WorkoutSession]>
    func fetchWorkoutSession(by id: String) -> Observable<WorkoutSession>
    func fetchActiveSession(for userId: String) -> Observable<WorkoutSession?>
    
    // Stats
    func fetchTotalDistance(for userId: String, in dateRange: DateRange) -> Single<Double>
    func fetchTotalCalories(for userid: String, in dateRange: DateRange) -> Single<Double>
    
    // Delete
    func deleteWorkoutSession(by id: String) -> Completable
}
