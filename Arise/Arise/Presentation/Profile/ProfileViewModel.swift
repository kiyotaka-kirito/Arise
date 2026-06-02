//
//  ProfileViewModel.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RxSwift

// MARK: - ProfileViewModel
final class ProfileViewModel {
    
    // MARK: - Dependencies
    private let getCurrentUserUseCase: GetCurrentUserUseCaseProtocol
    private let userRepository: UserRepositoryProtocol
    
    // MARK: - Outputs
    let currentUser = BehaviorSubject<User?>(value: nil)
    let isLoading = BehaviorSubject<Bool>(value: false)
    let errorMessage = PublishSubject<String>()
    
    // MARK: - Memory Management
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(
        getCurrentUserUseCase: GetCurrentUserUseCaseProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.userRepository = userRepository
    }
    
    // MARK: - Inputs
    func viewDidLoad() {
        
    }
    
}
