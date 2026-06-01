//
//  AuthServiceProtocol.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation
import RxSwift

// MARK: - AuthCredentials
struct AutAuthCredentials: Equatable {
    let email: String
    let password: String
}

// MARK: - AuthToken
struct AuthToken: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    
    var isValid: Bool { Date() < expiresAt }
    
    var needsRefresh: Bool {
        let fiveMinutes: TimeInterval = 5 * 60
        return Date().addingTimeInterval(fiveMinutes) >= expiresAt
    }
}

// MARK: - AuthServiceProtocol
protocol AuthServiceProtocol {
    
    // State
    var isAuthoricated: Observable<Bool> { get }
    var currentUserId: String? { get }
    
    // Authentication
    func signIn(with credentials: AutAuthCredentials) -> Single<User>
    func signUp(with credentials: AutAuthCredentials, name: String) -> Single<User>
    func signOut() -> Completable
    
    // Token Management (Keychain)
    func saveToken(_ token: AuthToken) -> Completable
    func retrieveToken() -> Single<AuthToken?>
    func refreshToken() -> Single<AuthToken>
    func clearAllTokens() -> Completable
}
