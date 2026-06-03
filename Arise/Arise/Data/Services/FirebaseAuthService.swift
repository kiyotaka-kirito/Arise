//
//  FirebaseAuthService.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 03/06/2026.
//

import Foundation
import FirebaseAuth
import RxSwift

// MARK: - FirebaseAuthService
final class FirebaseAuthService: AuthServiceProtocol {
    
    // MARK: - State
    private let isAuthenticatedSubject: BehaviorSubject<Bool>
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Init
    init() {
        // Check if Firebase already has a signed-in user
        let isLoggedIn = Auth.auth().currentUser != nil
        isAuthenticatedSubject = BehaviorSubject<Bool>(value: isLoggedIn)
        
        setupAuthStateListener()
    }
    
    // MARK: - Deinit
    deinit {
        // Always remove Firebase listeners to prevent memory leaks
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Protocol State
    var isAuthoricated: Observable<Bool> {
        isAuthenticatedSubject.asObservable()
    }
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Sign In
    func signIn(with credentials: AutAuthCredentials) -> Single<User> {
        return Single.create { single in
            Auth.auth().signIn(
                withEmail: credentials.email,
                password: credentials.password
            ) { authResult, error in
                
                if let error = error {
                    single(.failure(Self.mapFirebaseError(error)))
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    single(.failure(AuthError.unknown("No user returned")))
                    return
                }
                
                let user = Self.mapToDomainUser(firebaseUser)
                single(.success(user))
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    // MARK: - Sign Up
    func signUp(with credentials: AutAuthCredentials, name: String) -> Single<User> {
        return Single.create { single in
            Auth.auth().createUser(
                withEmail: credentials.email,
                password: credentials.password
            ) { authResult, error in
                
                if let error = error {
                    single(.failure(Self.mapFirebaseError(error)))
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    single(.failure(AuthError.unknown("No user returned")))
                    return
                }
                
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = name
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("⚠️ Display name update failed: \(error)")
                    }
                }
                
                var user = Self.mapToDomainUser(firebaseUser)
                user = User(
                    id: user.id,
                    fullName: name,
                    email: user.email,
                    dateOfBirth: Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
                    gender: .other,
                    heightInCm: 170.0,
                    weightInKg: 65.0
                )
                
                single(.success(user))
            }
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    // MARK: - Sign Out
    func signOut() -> Completable {
        return Completable.create { completable in
            do {
                try Auth.auth().signOut()
                completable(.completed)
            } catch {
                completable(.error(Self.mapFirebaseError(error)))
            }
            return Disposables.create()
        }
    }
    
    // MARK: - Token Management
    func saveToken(_ token: AuthToken) -> Completable { .empty() }
    
    func retrieveToken() -> Single<AuthToken?> {
        return Single.create { single in
            Auth.auth().currentUser?.getIDTokenResult { result, error in
                guard let result = result, error == nil else {
                    single(.success(nil))
                    return
                }
                
                let token = AuthToken(
                    accessToken: result.token,
                    refreshToken: "",
                    expiresAt: result.expirationDate
                )
                
                single(.success(token))
            }
            return Disposables.create()
        }
    }
    
    func refreshToken() -> Single<AuthToken> {
        return Single.create { single in
            Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { token, error in
                if let error = error {
                    single(.failure(Self.mapFirebaseError(error)))
                    return
                }
                
                guard let token = token else {
                    single(.failure(AuthError.tokenExpired))
                    return
                }
                
                let authToken = AuthToken(
                    accessToken: token,
                    refreshToken: "",
                    expiresAt: Date().addingTimeInterval(3600)
                )
                
                single(.success(authToken))
            }
            return Disposables.create()
        }
    }
    
    func clearAllTokens() -> Completable {
        return signOut()
    }
    
    // MARK: - Helpers
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticatedSubject.onNext(user != nil)
        }
    }
    
    private static func mapToDomainUser(_ firebaseUser: FirebaseAuth.User) -> User {
        User(
            id: firebaseUser.uid,
            fullName: firebaseUser.displayName ?? "Arise User",
            email: firebaseUser.email ?? "",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
            gender: .other,
            heightInCm: 170.0,
            weightInKg: 65.0
        )
    }
    
    private static func mapFirebaseError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        
        guard let errorCode = AuthErrorCode(rawValue: nsError.code) else {
            return .unknown(error.localizedDescription)
        }
        
        switch errorCode {
        case .invalidEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword
        case .wrongPassword, .invalidCredential:
            return .invalidCredentials
        case .userNotFound:
            return .invalidCredentials
        case .networkError:
            return .networkUnavailable
        case .userTokenExpired, .requiresRecentLogin:
            return.tokenExpired
        case .emailAlreadyInUse:
            return .unknown("This email is alredy registered. Please sign in.")
        case .tooManyRequests:
            return .unknown("Too many attempts. Please wait a moment and try again.")
        case .userDisabled:
            return .unknown("This account has been disabled. Please contact support.")
        default:
            return .unknown(error.localizedDescription)
        }
    }
    
}
