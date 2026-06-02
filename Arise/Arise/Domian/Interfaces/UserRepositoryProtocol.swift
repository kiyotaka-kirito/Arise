//
//  UserRepositoryProtocol.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation
import RxSwift

// MARK: - UserRepositoryProtocol
protocol UserRepositoryProtocol {
    
    // Fetch
    func fetchUser(by id: String) -> Observable<User>
    func fetchCurrentUser() -> Observable<User?>
    
    // Save / Update
    func saveUser(_ user: User) -> Completable
    func updateUser(_ user: User) -> Completable
    
    // Delete
    func deleteUser(by id: String) -> Completable
    
    // ProfileImage
    func saveProfileImage(_ data: Data, for userId: String) -> Single<String>
}
