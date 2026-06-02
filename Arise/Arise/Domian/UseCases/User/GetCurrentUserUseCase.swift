//
//  GetCurrentUserUseCase.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation
import RxSwift

// MARK: - Protocol
protocol GetCurrentUserUseCaseProtocol {
    func execute() -> Observable<User>
}

// MARK: - UseCase
final class GetCurrentUserUseCase: GetCurrentUserUseCaseProtocol {
    
    // Dependencies
    private let authService: AuthServiceProtocol
    private let userRepository: UserRepositoryProtocol
    
    // Init
    init(authService: AuthServiceProtocol, userRepository: UserRepositoryProtocol) {
        self.authService = authService
        self.userRepository = userRepository
    }
    
    // Execute
    func execute() -> Observable<User> {
        guard let userId = authService.currentUserId else {
            return .error(UserError.notLoggedIn)
        }
        return userRepository.fetchUser(by: userId)
    }
    
}

// MARK: - Error
enum UserError: LocalizedError {
    case notLoggedIn
    case userNotFound
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .notLoggedIn:  return "No user is currently signed in."
        case .userNotFound: return "User profile could not be found."
        case .updateFailed: return "Failed to update profile. Please try again."
        }
    }
}
