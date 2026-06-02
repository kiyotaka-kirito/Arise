//
//  HealthSummaryUseCase.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation
import RxSwift

// MARK: - HealthSummary
struct HealthSummary: Equatable {
    let userId: String
    let latestHeartRate: HealthMetric?
    let latestBloodOxygen: HealthMetric?
    let todaySteps: Double
    let todayCalories: Double
    let latestSleepDuration: HealthMetric?
    let generatedAt: Date
    
    var stepProgress: Double {
        min(todaySteps / 10_000, 1.0)
    }
}

// MARK: - Protocol
protocol FetchHealthSummaryUseCaseProtocol {
    func execute(for userId: String) -> Single<HealthSummary>
}

// MARK: - UseCase
final class FetchHealthSummaryUseCase: FetchHealthSummaryUseCaseProtocol {
    
    // Dependencies
    private let healthRepository: HealthRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol
    
    // Init
    init(healthRepository: HealthRepositoryProtocol, workoutRepository: WorkoutRepositoryProtocol) {
        self.healthRepository = healthRepository
        self.workoutRepository = workoutRepository
    }
    
    // Execute
    func execute(for userId: String) -> Single<HealthSummary> {
        return Single.zip(
            latestMetric(for: userId, type: .heartRate),
            latestMetric(for: userId, type: .bloodOxygen),
            todaysSteps(for: userId),
            todaysCalories(for: userId),
            latestMetric(for: userId, type: .sleepDuration)
        )
        .map { heartRate, bloodOxygen, steps, calories, sleep in
            HealthSummary(
                userId: userId,
                latestHeartRate: heartRate,
                latestBloodOxygen: bloodOxygen,
                todaySteps: steps,
                todayCalories: calories,
                latestSleepDuration: sleep,
                generatedAt: Date()
            )
        }
    }
    
    // Helpers
    private func latestMetric(for userId: String, type: MetricType) -> Single<HealthMetric?> {
        healthRepository
            .fetchLatestMetric(for: userId, type: type)
            .take(1)
            .asSingle()
    }
    
    private func todaysSteps(for userId: String) -> Single<Double> {
        healthRepository
            .observeTodaySteps(for: userId)
            .take(1)
            .asSingle()
    }
    
    private func todaysCalories(for userId: String) -> Single<Double> {
        workoutRepository
            .fetchTotalCalories(for: userId, in: .today)
    }
    
}
