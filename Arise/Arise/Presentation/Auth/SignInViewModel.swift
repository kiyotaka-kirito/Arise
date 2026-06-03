//
//  SignInViewModel.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 03/06/2026.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - Validation State
enum ValidationState: Equatable {
    case idle
    case valid
    case invalid(String)
}

// MARK: - SignInViewModel
final class SignInViewModel {
    
    // MARK: - Dependencies
    private let signInUseCase: SignInUseCaseProtocol
    
    // MARK: - Inputs
    let emailInput      = BehaviorRelay<String>(value: "")
    let passwordInput   = BehaviorRelay<String>(value: "")
    
    // MARK: - Outputs
    let isLoading       = BehaviorRelay<Bool>(value: false)
    let errorMessage    = PublishRelay<String>()
    let signInSuccess   = PublishRelay<User>()
    
    // MARK: - Validation Outputs
    let emailValidation     = BehaviorRelay<ValidationState>(value: .idle)
    let passwordValidation  = BehaviorRelay<ValidationState>(value: .idle)
    let isFormValid         = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Memory Management
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(signInUseCase: SignInUseCaseProtocol) {
        self.signInUseCase = signInUseCase
        setupLiveValidation()
    }
    
    // MARK: - Input: Sign In
    func signInTapped() {
        guard isFormValid.value else {
            validateEmail(emailInput.value)
            validatePassword(passwordInput.value)
            return
        }
        
        isLoading.accept(true)
        
        let credentials = AutAuthCredentials(
            email: emailInput.value.trimmingCharacters(in: .whitespaces),
            password: passwordInput.value
        )
        
        signInUseCase.execute(with: credentials)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] user in
                    self?.isLoading.accept(false)
                    self?.signInSuccess.accept(user)
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
        emailInput
            .skip(1)
            .debounce(.milliseconds(400), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] email in
                self?.validateEmail(email)
            })
            .disposed(by: disposeBag)
        
        passwordInput
            .skip(1)
            .subscribe(onNext: { [weak self] password in
                self?.validatePassword(password)
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(emailValidation, passwordValidation)
            .map { email, password in
                email == .valid && password == .valid
            }
            .bind(to: isFormValid)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Validatiors
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
            passwordValidation.accept(.invalid("At least 8 characters required"))
        } else {
            passwordValidation.accept(.valid)
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
    
}
