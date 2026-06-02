//
//  RealmHealthRepostiory.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RealmSwift
import RxSwift

// MARK: - RealmHealthRepository
final class RealmHealthRepository: HealthRepositoryProtocol {
    
    // MARK: - Realm Configuration
    private let configuration: Realm.Configuration
    
    // MARK: - Init
    init(configuration: Realm.Configuration = .defaultConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Helper
    private func makeRealm() throws -> Realm {
        try Realm(configuration: configuration)
    }
    
    // MARK: - Protocol Implementation
    func saveMetric(_ metric: HealthMetric) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(HealthError.saveFailed))
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                let realmMetric = RealmHealthMetric(from: metric)
                
                try realm.write {
                    realm.add(realmMetric, update: .modified)
                }
                
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func saveMetrics(_ metrics: [HealthMetric]) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(HealthError.saveFailed))
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                try realm.write {
                    metrics.forEach { metric in
                        realm.add(RealmHealthMetric(from: metric), update: .modified)
                    }
                }
                
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func fetchMetrics(for userId: String, type: MetricType, in dateRange: DateRange) -> Observable<[HealthMetric]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(HealthError.fetchFailed)
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                // Realm query: filter by userId, type, AND data range
                let results = realm.objects(RealmHealthMetric.self)
                    .filter("userId == %@ AND type == %@ AND recordedAt >= %@ AND recordedAt <= %@",
                            userId,
                            type.rawValue,
                            dateRange.start,
                            dateRange.end
                    )
                    .sorted(byKeyPath: "recordedAt", ascending: false)
                
                let metrics = results.compactMap { $0.toDomain() }
                observer.onNext(Array(metrics))
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func fetchLatestMetric(for userId: String, type: MetricType) -> Observable<HealthMetric?> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                let metrics = realm.objects(RealmHealthMetric.self)
                    .filter("userId == %@ AND type == %@", userId, type.rawValue)
                    .sorted(byKeyPath: "recordedAt", ascending: false)
                    .first?
                    .toDomain()
                
                observer.onNext(metrics)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func observeTodaySteps(for userId: String) -> Observable<Double> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(0)
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                let startOfDay = Calendar.current.startOfDay(for: Date())
                
                let totalSteps = realm.objects(RealmHealthMetric.self)
                    .filter("userId == %@ AND type == %@ AND recordedAt >= %@",
                            userId,
                            MetricType.steps.rawValue,
                            startOfDay
                    )
                    .sum(ofProperty: "value") as Double
                
                observer.onNext(totalSteps)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func deleteAllMetrics(for userId: String) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(HealthError.saveFailed))
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                let metrics = realm.objects(RealmHealthMetric.self)
                    .filter("userId == %@", userId)
                
                try realm.write {
                    realm.delete(metrics)
                }
                
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
}

// MARK: - Health Error
enum HealthError: LocalizedError {
    case saveFailed
    case fetchFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed: return "Failed to save health data."
        case .fetchFailed: return "Failed to fetch health data."
        }
    }
}
