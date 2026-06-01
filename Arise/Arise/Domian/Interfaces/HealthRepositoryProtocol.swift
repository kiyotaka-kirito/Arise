//
//  HealthRepositoryProtocol.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation
import RxSwift

// MARK: - Date Range
struct DateRange: Equatable {
    let start: Date
    let end: Date
    
    static var lastWeek: DateRange {
        DateRange(start: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(), end: Date())
    }
    
    static var lastMonth: DateRange {
        DateRange(start: Calendar.current.date(byAdding: .month, value: -30, to: Date()) ?? Date(), end: Date())
    }
    
    static var today: DateRange {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return DateRange(start: startOfDay, end: Date())
    }
}

// MARK: - HealthRepositoryProtocol
protocol HealthRepositoryProtocol {
    
    // Save
    func saveMetric(_ metric: HealthMetric) -> Completable
    func saveMetrics(_ metrics: [HealthMetric]) -> Completable
    
    // Fetch
    func fetchMetrics(for userId: String, type: MetricType, in dateRange: DateRange) -> Observable<[HealthMetric]>
    func fetchLatestMetric(for userId: String, type: MetricType) -> Observable<HealthMetric?>
    
    func observeTodaySteps(for userId: String) -> Observable<Double>
    
    // Delete
    func deleteAllMetrics(for userId: String) -> Completable
    
}
