//
//  SignUpViewModel.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 03/06/2026.
//

import Foundation
import SwiftUI
import RxSwift
import RxCocoa

// MARK: - SignUpViewModel
final class SignUpViewModel {
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let userRepository: UserRepositoryProtocol
    
    // MARK: - Inputs
    let nameInput            = BehaviorRelay<String>(value: "")
    let emailInput           = BehaviorRelay<String>(value: "")
    let passwordInput        = BehaviorRelay<String>(value: "")
    let confirmPasswordInput = BehaviorRelay<String>(value: "")
    
    // MARK: - Outputs
    let isLoading       = BehaviorRelay<Bool>(value: false)
    let errorMessage    = PublishRelay<String>()
    let signUpSuccess   = PublishRelay<User>()
    
    // MARK: - Validation Outputs
    let nameValidation      = BehaviorRelay<ValidationState>(value: .idle)
    let emailValidation     = BehaviorRelay<ValidationState>(value: .idle)
    let passwordValidation  = BehaviorRelay<ValidationState>(value: .idle)
    let confirmValidation   = BehaviorRelay<ValidationState>(value: .idle)
    let isFormValid         = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Password Strength
    let passwordStrength    = BehaviorRelay<PasswordStrength>(value: .empty)
    
    // MARK: - Memory Management
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(
        authService: AuthServiceProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.authService = authService
        self.userRepository = userRepository
        setupLiveValidation()
    }
    
    // MARK: - Input: Sign Up
    func signUpTapped() {
        guard isFormValid.value else {
            validateName(nameInput.value)
            validateEmail(emailInput.value)
            validatePassword(passwordInput.value)
            validateConfirmPassword(confirmPasswordInput.value)
            return
        }
        
        isLoading.accept(true)
        
        let credentials = AutAuthCredentials(
            email: emailInput.value.trimmingCharacters(in: .whitespaces),
            password: passwordInput.value
        )
        
        authService.signUp(
            with: credentials,
            name: nameInput.value.trimmingCharacters(in: .whitespaces)
        )
        .observe(on: MainScheduler.instance)
        .flatMap { [weak self] user -> Single<User> in
            guard let self = self else { return.just(user) }
            return self.userRepository.saveUser(user)
                .andThen(Single.just(user))
        }
        .subscribe(
            onSuccess: { [weak self] user in
                self?.isLoading.accept(false)
                self?.signUpSuccess.accept(user)
            },
            onFailure: { [weak self] error in
                self?.isLoading.accept(false)
                self?.errorMessage.accept(error.localizedDescription)
            }
        )
        .disposed(by: disposeBag)
        
    }
    
    // MARK: - Live Validation Setup
    private func setupLiveValidation() {
        nameInput
            .skip(1)
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.validateName($0) })
            .disposed(by: disposeBag)
        
        emailInput
            .skip(1)
            .debounce(.milliseconds(400), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.validateEmail($0) })
            .disposed(by: disposeBag)
        
        passwordInput
            .skip(1)
            .subscribe(onNext: { [weak self] password in
                self?.validatePassword(password)
                self?.passwordStrength.accept(PasswordStrength(password: password))
                
                // Re-validate confirm
                if let self = self, !self.confirmPasswordInput.value.isEmpty {
                    self.validateConfirmPassword(self.confirmPasswordInput.value)
                }
            })
            .disposed(by: disposeBag)
        
        confirmPasswordInput
            .skip(1)
            .subscribe(onNext: { [weak self] in self?.validateConfirmPassword($0) })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(
            nameValidation,
            emailValidation,
            passwordValidation,
            confirmValidation
        )
        .map { name, email, password, confirm in
            [name, email, password, confirm].allSatisfy { $0 == .valid }
        }
        .bind(to: isFormValid)
        .disposed(by: disposeBag)
    }
    
    // MARK: - Validatiors
    private func validateName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            nameValidation.accept(.invalid("Name is required"))
        } else if trimmed.count < 2 {
            nameValidation.accept(.invalid("Name must be at least 2 characters"))
        } else {
            nameValidation.accept(.valid)
        }
    }
    
    private func validateEmail(_ email: String) {
        if email.isEmpty {
            emailValidation.accept(.invalid("Email is required"))
        } else if !isValidEmail(email) {
            emailValidation.accept(.invalid("Enter a valid email address"))
        } else {
            emailValidation.accept(.valid)
        }
    }
    
    private func validatePassword(_ password: String) {
        if password.isEmpty {
            passwordValidation.accept(.invalid("Password is required"))
        } else if password.count < 8 {
            passwordValidation.accept(.invalid("Minimum 8 characters"))
        } else if password.rangeOfCharacter(from: .decimalDigits) == nil {
            passwordValidation.accept(.invalid("Include at least one number"))
        } else {
            passwordValidation.accept(.valid)
        }
    }
    
    private func validateConfirmPassword(_ confirm: String) {
        if confirm.isEmpty {
            confirmValidation.accept(.invalid("Please confirm your password"))
        } else if confirm != passwordInput.value {
            confirmValidation.accept(.invalid("Password do not match"))
        } else {
            confirmValidation.accept(.valid)
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
    
}

// MARK: - PasswordStrength
enum PasswordStrength {
    case empty
    case weak
    case fair
    case strong
    case veryStrong
    
    init(password: String) {
        guard !password.isEmpty else { self = .empty; return }
        
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",./<>?")) != nil { score += 1 }
        
        switch score {
        case 0...1: self = .weak
        case 2:     self = .fair
        case 3:     self = .strong
        default:     self = .veryStrong
        }
    }
    
    var label: String {
        switch self {
        case .empty:        return ""
        case .weak:         return "Weak"
        case .fair:         return "Fair"
        case .strong:       return "Strong"
        case .veryStrong:   return "Very Strong"
        }
    }
    
    var color: Color {
        switch self {
        case .empty:        return .clear
        case .weak:         return .red
        case .fair:         return .orange
        case .strong:       return .green
        case .veryStrong:   return Color(red: 0.18, green: 0.80, blue: 0.44)
        }
    }
    
    var progress: Double {
        switch self {
        case .empty:        return 0
        case .weak:         return 0.25
        case .fair:         return 0.5
        case .strong:       return 0.75
        case .veryStrong:   return 1.0
        }
    }
}
