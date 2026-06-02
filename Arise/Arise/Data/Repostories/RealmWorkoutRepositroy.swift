//
//  RealmWorkoutRepositroy.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RealmSwift
import RxSwift

// MARK: - RealmWorkoutRepositroy
final class RealmWorkoutRepositroy: WorkoutRepositoryProtocol {
    
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
    func createWorkoutSession(_ session: WorkoutSession) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(WorkoutError.saveFailed))
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                try realm.write {
                    realm.add(RealmWorkoutSession(from: session))
                }
                
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func updateWorkoutSession(_ session: WorkoutSession) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(WorkoutError.saveFailed))
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                try realm.write {
                    realm.add(RealmWorkoutSession(from: session), update: .all)
                }
                
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func completeWorkoutSession(_ session: WorkoutSession) -> Completable {
        return updateWorkoutSession(session)
    }
    
    func fetchWorkoutHistory(for userId: String, limit: Int) -> Observable<[WorkoutSession]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WorkoutError.sessionNotFound)
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                // Realm query: filter by userId AND status
                let results = realm.objects(RealmWorkoutSession.self)
                    .filter("userId == %@ AND status == %@",
                            userId,
                            WorkoutStatus.completed.rawValue
                    )
                    .sorted(byKeyPath: "startTime", ascending: false)
                
                // Apply limit in Swift (Realm doesn't have)
                let limited = Array(results.prefix(limit))
                let sessions = limited.compactMap { $0.toDomain() }
                observer.onNext(sessions)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func fetchWorkouts(for userId: String, type: WorkoutType, in dateRange: DateRange) -> Observable<[WorkoutSession]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WorkoutError.sessionNotFound)
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                let results = realm.objects(RealmWorkoutSession.self)
                    .filter("userId == %@ AND status == %@ AND startTime >= %@ AND startTime <= %@",
                            userId,
                            type.rawValue,
                            dateRange.start,
                            dateRange.end
                    )
                    .sorted(byKeyPath: "startTime", ascending: false)
                
                observer.onNext(results.compactMap { $0.toDomain() })
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func fetchWorkoutSession(by id: String) -> Observable<WorkoutSession> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WorkoutError.sessionNotFound)
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                guard let session = realm.object(ofType: RealmWorkoutSession.self, forPrimaryKey: id)?.toDomain() else {
                    observer.onError(WorkoutError.sessionNotFound)
                    return Disposables.create()
                }
                
                observer.onNext(session)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func fetchActiveSession(for userId: String) -> Observable<WorkoutSession?> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                let session = realm.objects(RealmWorkoutSession.self)
                    .filter("userId == %@ AND status == %@",
                            userId,
                            WorkoutStatus.active.rawValue
                    )
                    .first?
                    .toDomain()
                
                observer.onNext(session)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func fetchTotalDistance(for userId: String, in dateRange: DateRange) -> Single<Double> {
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.success(0))
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                let total = realm.objects(RealmWorkoutSession.self)
                    .filter("userId == %@ AND status == %@ AND startTime >= %@ AND startTime <= %@",
                            userId,
                            WorkoutStatus.completed.rawValue,
                            dateRange.start,
                            dateRange.end
                    )
                    .sum(ofProperty: "totalDistanceMeters") as Double
                
                single(.success(total))
            } catch {
                single(.failure(error))
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func fetchTotalCalories(for userId: String, in dateRange: DateRange) -> Single<Double> {
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.success(0))
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                let total = realm.objects(RealmWorkoutSession.self)
                    .filter("userId == %@ AND status == %@ AND startTime >= %@ AND startTime <= %@",
                            userId,
                            WorkoutStatus.completed.rawValue,
                            dateRange.start,
                            dateRange.end
                    )
                    .sum(ofProperty: "totalCaloriesBurned") as Double
                
                single(.success(total))
            } catch {
                single(.failure(error))
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func deleteWorkoutSession(by id: String) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(WorkoutError.saveFailed))
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                guard let session = realm.object(ofType: RealmWorkoutSession.self, forPrimaryKey: id) else {
                    completable(.error(WorkoutError.sessionNotFound))
                    return Disposables.create()
                }
                
                try realm.write {
                    realm.delete(session)
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
