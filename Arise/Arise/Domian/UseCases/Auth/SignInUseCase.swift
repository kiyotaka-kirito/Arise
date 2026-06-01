//
//  SignInUseCase.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation
import RxSwift

// MARK: - Protocol
protocol SignInUseCaseProtocol {
    func execute(with credentials: AutAuthCredentials) -> Single<User>
}

// MARK: - UseCase
final class SignInUseCase: SignInUseCaseProtocol {
    
    // Dependencies
    private let authService: AuthServiceProtocol
    private let userRepository: UserRepositoryProtocol
    
    // Init
    init(authService: AuthServiceProtocol, userRepository: UserRepositoryProtocol) {
        self.authService = authService
        self.userRepository = userRepository
    }
    
    // Execute
    func execute(with credentials: AutAuthCredentials) -> Single<User> {
        guard isValidEmail(credentials.email) else {
            return .error(AuthError.invalidEmail)
        }
        
        guard isValidPassword(credentials.password) else {
            return .error(AuthError.weakPassword)
        }
        
        return authService.signIn(with: credentials)
    }
    
    // Helpers
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHS %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8 && password.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
}

// MARK: Error
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case invalidCredentials
    case tokenExpired
    case networkUnavailable
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:          return "Please enter a valid email address."
        case .weakPassword:          return "Password must be at least 8 characters and contains a number."
        case .invalidCredentials:    return "Incorrect email and password. Please try again."
        case .tokenExpired:          return "Your session has expired. Please sign in again."
        case .networkUnavailable:    return "No internet connection. Please check your network."
        case .unknown(let messsage): return messsage
        }
    }
}
