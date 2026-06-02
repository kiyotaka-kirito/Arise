//
//  ProfileViewModel.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - ProfileSection
enum ProfileSection: String, CaseIterable {
    case health     = "Health Stats"
    case activity   = "Activity Summary"
    case settings   = "Settings"
}

// MARK: - ProfileViewModel
final class ProfileViewModel {
    
    // MARK: - Dependencies
    private let getCurrentUserUseCase: GetCurrentUserUseCaseProtocol
    private let userRepository: UserRepositoryProtocol
    private let authService: AuthServiceProtocol
    
    // MARK: - Outputs
    let currentUser     = BehaviorRelay<User?>(value: nil)
    let isLoading       = BehaviorRelay<Bool>(value: false)
    let errorMessage    = PublishRelay<String>()
    let signedOut       = PublishRelay<Void>()
    let saveSuccess     = PublishRelay<Void>()
    
    // MARK: - Editable Fields (two-way binding)
    let editedFullName  = BehaviorRelay<String>(value: "")
    let editedWeight    = BehaviorRelay<Double>(value: 0)
    let editedHeight    = BehaviorRelay<Double>(value: 0)
    
    // MARK: - Memory Management
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(
        getCurrentUserUseCase: GetCurrentUserUseCaseProtocol,
        userRepository: UserRepositoryProtocol,
        authService: AuthServiceProtocol
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.userRepository = userRepository
        self.authService = authService
    }
    
    // MARK: - Inputs
    func viewDidLoad() {
        loadUserProfile()
    }
    
    func saveChanges() {
        guard var user = currentUser.value else { return }
        
        // Validate
        guard !editedFullName.value.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage.accept("Name cannot be empty.")
            return
        }
        
        guard editedWeight.value > 0, editedHeight.value > 0 else {
            errorMessage.accept("Please enter valid height and weight.")
            return
        }
        
        // Apply edits to user entity
        user.fullName       = editedFullName.value
        user.weightInKg     = editedWeight.value
        user.heightInCm     = editedHeight.value
        
        isLoading.accept(true)
        
        userRepository.updateUser(user)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onCompleted: { [weak self] in
                    guard let self = self else { return }
                    self.isLoading.accept(false)
                    self.currentUser.accept(user)
                    self.saveSuccess.accept(())
                },
                onError: { [weak self] error in
                    self?.isLoading.accept(false)
                    self?.errorMessage.accept(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
        
    }
    
    func signOut() {
        authService.signOut()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onCompleted: { [weak self] in
                    self?.signedOut.accept(())
                },
                onError: { [weak self] error in
                    self?.errorMessage.accept(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }
    
    // MARK: - LoadUserProfile
    private func loadUserProfile() {
        isLoading.accept(true)
        
        getCurrentUserUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] user in
                    guard let self = self else { return }
                    self.currentUser.accept(user)
                    self.isLoading.accept(false)
                    
                    // Pre-fill editable fields
                    self.editedFullName.accept(user.fullName)
                    self.editedWeight.accept(user.weightInKg)
                    self.editedHeight.accept(user.heightInCm)
                },
                onError: { [weak self] error in
                    self?.isLoading.accept(false)
                }
            )
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Computed Display Helpers
    var bmiDisplay: String {
        guard let user = currentUser.value else { return "--" }
        return "\(user.bmi) - \(user.bmiCategory.rawValue)"
    }
    
    var ageDisplay: String {
        guard let user = currentUser.value else { return "--" }
        return "\(user.age) years"
    }
    
    var heightDisplay: String {
        guard let user = currentUser.value else { return "--" }
        return "\(Int(user.heightInCm)) cm"
    }
    
    var weightDisplay: String {
        guard let user = currentUser.value else { return "--" }
        return "\(user.weightInKg) kg"
    }
    
}
