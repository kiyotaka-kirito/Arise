//
//  KeychainAuthService.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RxSwift

final class KeychainAuthService: AuthServiceProtocol {
    
    // MARK: - State
    private let isAuthenticatedSubject = BehaviorSubject<Bool>(value: false)
    
    var isAuthoricated: Observable<Bool> {
        isAuthenticatedSubject.asObservable()
    }
    
    var currentUserId: String? { nil }
    
    // MARK: - Stubs
    func signIn(with credentials: AutAuthCredentials) -> Single<User> {
        .error(AuthError.networkUnavailable)
    }
    
    func signUp(with credentials: AutAuthCredentials, name: String) -> Single<User> {
        .error(AuthError.networkUnavailable)
    }
    
    func signOut() -> Completable { .empty() }
    
    func saveToken(_ token: AuthToken) -> Completable { .empty() }
    
    func retrieveToken() -> Single<AuthToken?> { .just(nil) }
    
    func refreshToken() -> Single<AuthToken> {
        .error(AuthError.tokenExpired)
    }
    
    func clearAllTokens() -> Completable { .empty() }
    
}
