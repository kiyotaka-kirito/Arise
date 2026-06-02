//
//  KeychainAuthService.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RxSwift
import Security

// MARK: - KeychainHelper
private final class KeychainHelper {
    
    static let shared = KeychainHelper()
    private init() {}
    
    // MARK: - Save
    func save(_ data: Data, for key: String) -> Bool {
        // Delete existing entry first
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      key,
            kSecValueData as String:        data,
            kSecAttrAccessible as String:   kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Read
    func read(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrAccount as String:  key,
            kSecReturnData as String:   true,
            kSecMatchLimit as String:   kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    // MARK: - Delete
    @discardableResult
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrAccount as String:  key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}


final class KeychainAuthService: AuthServiceProtocol {
    
    // MARK: - Keychain Keys
    private enum Keys {
        static let authToken    = "com.arise.auth.token"
         static let userId       = "com.arise.auth.userId"
         static let userEmail    = "com.arise.auth.email"
    }
    
    // MARK: - State
    private let isAuthenticatedSubject: BehaviorSubject<Bool>
    private var cachedUserId: String?
    
    // MARK: - Init
    init() {
        // Check Keychain on launch to restore session
        let hasToken = KeychainHelper.shared.read(key: Keys.authToken) != nil
        isAuthenticatedSubject = BehaviorSubject<Bool>(value: hasToken)
        
        // Restore cached userId
        if let userIdData = KeychainHelper.shared.read(key: Keys.userId) {
            cachedUserId = String(data: userIdData, encoding: .utf8)
        }
    }
    
    // MARK: - Protocol Implementation
    var isAuthoricated: Observable<Bool> {
        isAuthenticatedSubject.asObservable()
    }
    
    var currentUserId: String? { cachedUserId }
    
    // MARK: - Sign In
    func signIn(with credentials: AutAuthCredentials) -> Single<User> {
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(AuthError.unknown("Service unavaliable")))
                return Disposables.create()
            }
            
            // Simulate network delay
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.8) {
                // Create a mock
                let mockUser = User(
                    id: "arise_user_001",
                    fullName: "Sung-Jin Woo",
                    email: credentials.email,
                    dateOfBirth: Calendar.current.date(
                        byAdding: .year,
                        value: -28,
                        to: Date()
                    ) ?? Date(),
                    gender: .male,
                    heightInCm: 178.0,
                    weightInKg: 74.5
                )
                
                // Create and save mock
                let mockToken = AuthToken(
                    accessToken: UUID().uuidString,
                    refreshToken: UUID().uuidString,
                    expiresAt: Date().addingTimeInterval(3600 * 24 * 7)
                )
                
                // Save token and userId to Keychain
                self.persistSession(token: mockToken, user: mockUser)
                single(.success(mockUser))
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Sign Up
    func signUp(with credentials: AutAuthCredentials, name: String) -> Single<User> {
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(AuthError.unknown("Service unavaliable")))
                return Disposables.create()
            }
            
            // Simulate network delay
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) {
                // Create a mock
                let newUser = User(
                    id: UUID().uuidString,
                    fullName: name,
                    email: credentials.email,
                    dateOfBirth: Calendar.current.date(
                        byAdding: .year,
                        value: -25,
                        to: Date()
                    ) ?? Date(),
                    gender: .other,
                    heightInCm: 170.0,
                    weightInKg: 65.0
                )
                
                // Create and save mock
                let mockToken = AuthToken(
                    accessToken: UUID().uuidString,
                    refreshToken: UUID().uuidString,
                    expiresAt: Date().addingTimeInterval(3600 * 24 * 7)
                )
                
                // Save token and userId to Keychain
                self.persistSession(token: mockToken, user: newUser)
                single(.success(newUser))
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Sign Out
    func signOut() -> Completable {
        return Completable.create { [weak self] completable in
            self?.clearSession()
            completable(.completed)
            return Disposables.create()
        }
    }
    
    // MARK: - Token Managemnet
    func saveToken(_ token: AuthToken) -> Completable {
        return Completable.create { completable in
            guard let data = try? JSONEncoder().encode(token) else {
                completable(.error(AuthError.unknown("Token encoding failed")))
                return Disposables.create()
            }
            _ = KeychainHelper.shared.save(data, for: Keys.authToken)
            completable(.completed)
            return Disposables.create()
        }
    }
    
    func retrieveToken() -> Single<AuthToken?> {
        return Single.create { single in
            guard
                let data = KeychainHelper.shared.read(key: Keys.authToken),
                let token = try? JSONDecoder().decode(AuthToken.self, from: data)
            else {
                single(.success(nil))
                return Disposables.create()
            }
            single(.success(token))
            return Disposables.create()
        }
    }
    
    func refreshToken() -> Single<AuthToken> {
        return Single.create { single in
            single(.failure(AuthError.tokenExpired))
            return Disposables.create()
        }
    }
    
    func clearAllTokens() -> Completable {
        return Completable.create { [weak self] completable in
            self?.clearSession()
            completable(.completed)
            return Disposables.create()
        }
    }
    
    // MARK: - Helpers
    private func persistSession(token: AuthToken, user: User) {
        // Save token
        if let tokenData = try? JSONEncoder().encode(token) {
            _ = KeychainHelper.shared.save(tokenData, for: Keys.authToken)
        }
        
        // Save userId
        if let userIdData = user.id.data(using: .utf8) {
            _ = KeychainHelper.shared.save(userIdData, for: Keys.userId)
        }
        
        // Save email
        if let emailData = user.email.data(using: .utf8) {
            _ = KeychainHelper.shared.save(emailData, for: Keys.userEmail)
        }
        
        cachedUserId = user.id
        
        // Published authenticated state
        isAuthenticatedSubject.onNext(true)
    }
    
    private func clearSession() {
        KeychainHelper.shared.delete(key: Keys.authToken)
        KeychainHelper.shared.delete(key: Keys.userId)
        KeychainHelper.shared.delete(key: Keys.userEmail)
        cachedUserId = nil
        isAuthenticatedSubject.onNext(false)
    }
}

