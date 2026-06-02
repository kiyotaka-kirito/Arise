//
//  RealmUserRepository.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RealmSwift
import RxSwift

// MARK: - RealmUserRepository
final class RealmUserRepository: UserRepositoryProtocol {
    
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
    func fetchUser(by id: String) -> Observable<User> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(UserError.userNotFound)
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                guard
                    // Realm's object is the fastest lookup
                    let realmUser = realm.object(ofType: RealmUser.self, forPrimaryKey: id),
                    let user = realmUser.toDomain() else {
                    observer.onError(UserError.userNotFound)
                    return Disposables.create()
                }
                
                observer.onNext(user)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
        // Always observe DB reads on a background thread
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func fetchCurrentUser() -> Observable<User?> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                let user = realm.objects(RealmUser.self).first?.toDomain()
                observer.onNext(user)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func saveUser(_ user: User) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(UserError.updateFailed))
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                let realmUser = RealmUser(from: user)
                
                try realm.write {
                    realm.add(realmUser, update: .modified)
                }
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func updateUser(_ user: User) -> Completable {
        return saveUser(user)
    }
    
    func deleteUser(by id: String) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(UserError.userNotFound))
                return Disposables.create()
            }
            
            do {
                let realm = try self.makeRealm()
                
                guard
                    let realmUser = realm.object(ofType: RealmUser.self, forPrimaryKey: id)
                else {
                    completable(.error(UserError.userNotFound))
                    return Disposables.create()
                }
                
                try realm.write {
                    realm.delete(realmUser)
                }
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func saveProfileImage(_ data: Data, for userId: String) -> Single<String> {
        return Single.create { single in
            let fileName = "profile_\(userId).jpg"
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(fileName)
            
            do {
                try data.write(to: fileURL)
                single(.success(fileURL.absoluteString))
            } catch {
                single(.failure(error))
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .utility))
    }
    
}
