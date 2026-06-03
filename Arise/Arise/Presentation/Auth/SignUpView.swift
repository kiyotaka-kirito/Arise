//
//  SignUpView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 03/06/2026.
//

import SwiftUI
import RxSwift
import Combine
import RxRelay

// MARK: - SignUpView
struct SignUpView: View {
    
    @StateObject private var wrapper: SignUpViewModelWrapper
    let onSignUpSuccess: (User) -> Void
    let onNavigateToSignIn: () -> Void
    
    init(
        viewModel: SignUpViewModel,
        onSignUpSuccess: @escaping (User) -> Void,
        onNavigateToSignIn: @escaping () -> Void
    ) {
        _wrapper = StateObject(
            wrappedValue: SignUpViewModelWrapper(viewModel: viewModel)
        )
        self.onSignUpSuccess = onSignUpSuccess
        self.onNavigateToSignIn = onNavigateToSignIn
    }
    
    @State private var contnetAppeared = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.arisePrimaryFallback.opacity(0.1),
                    Color.ariseBackgroundFallback,
                    Color.ariseBackgroundFallback
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    headerSection
                        .padding(.top, 50)
                        .padding(.bottom, 32)
                    
                    formSection
                        .padding(.horizontal, 50)
                    
                    signUpButton
                        .padding(.horizontal, 28)
                        .padding(.top, 24)
                    
                    signInPrompt
                        .padding(.top, 24)
                        .padding(.bottom, 48)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                contnetAppeared = true
            }
        }
        .onChange(of: wrapper.signUpSuccessUser) { _, user in
            guard let user = user else { return }
            onSignUpSuccess(user)
        }
        .alert("Sign Up Failed", isPresented: $wrapper.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(wrapper.errorText)
        }
    }

}

// MARK: - Components
extension SignUpView {
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Create Account")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .opacity(contnetAppeared ? 1 : 0)
                .offset(y: contnetAppeared ? 0 : 20)
            
            Text("Start your health journey today")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .opacity(contnetAppeared ? 1 : 0)
                .offset(y: contnetAppeared ? 0 : 12)
        }
    }
    
    // MARK: - Form
    private var formSection: some View {
        VStack(spacing: 14) {
            
            AriseTextField(
                icon: "person",
                placeholder: "Full name",
                text: $wrapper.name,
                validation: wrapper.nameValidation
            )
            
            AriseTextField(
                icon: "envelope",
                placeholder: "Email address",
                text: $wrapper.email,
                validation: wrapper.emailValidation,
                keyboardType: .emailAddress
            )
            
            VStack(spacing: 6) {
                AriseTextField(
                    icon: "lock",
                    placeholder: "Password",
                    text: $wrapper.password,
                    validation: wrapper.passwordValidation,
                    isSecure: true
                )
                
                if !wrapper.password.isEmpty {
                    PasswordStrengthBar(strength: wrapper.passwordStrength)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                }
            }
            .animation(.spring(response: 0.4), value: wrapper.password.isEmpty)
            
            AriseTextField(
                icon: "lock.shield",
                placeholder: "Confirm password",
                text: $wrapper.confirmPassword,
                validation: wrapper.confirmValidation,
                isSecure: true
            )
            
            // Term note
            Text("By signing up you agree to our Terms of Serive and Privacy Policy.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .opacity(contnetAppeared ? 1 : 0)
        .offset(y: contnetAppeared ? 0 : 20)
    }
    
    // MARK: - Sign Up Button
    private var signUpButton: some View {
        Button {
            wrapper.signUpTapped()
        } label: {
            ZStack {
                if wrapper.isLoading {
                    ProgressView().tint(.white).scaleEffect(1.1)
                } else {
                    HStack(spacing: 8) {
                        Text("Create Account")
                            .fontWeight(.bold)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        wrapper.isFormValid
                        ? LinearGradient(
                            colors: [Color.arisePrimaryFallback, Color.arisePrimaryFallback.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Color.secondary.opacity(0.3), Color.secondary.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: wrapper.isFormValid
                        ? Color.arisePrimaryFallback.opacity(0.4)
                        : .clear,
                        radius: 16, x: 0, y: 8
                    )
            )
        }
        .disabled(wrapper.isLoading)
    }
    
    // MARK: - Sign In Prompt
    private var signInPrompt: some View {
        HStack(spacing: 4) {
            Text("Already have an account?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Sign In") {
                onNavigateToSignIn()
            }
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(Color.arisePrimaryFallback)
        }
    }
}

// MARK: - SignUpViewModelWrapper
@MainActor
final class SignUpViewModelWrapper: ObservableObject {
    
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var isFormValid: Bool = false
    @Published var nameValidation: ValidationState = .idle
    @Published var emailValidation: ValidationState = .idle
    @Published var passwordValidation: ValidationState = .idle
    @Published var confirmValidation: ValidationState = .idle
    @Published var passwordStrength: PasswordStrength = .empty
    @Published var showError: Bool = false
    @Published var errorText: String = ""
    @Published var signUpSuccessUser: User? = nil
    
    private let viewModel: SignUpViewModel
    private var disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: SignUpViewModel) {
        self.viewModel = viewModel
        bindToViewModel()
    }
    
    private func bindToViewModel() {
        
        $name
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.viewModel.nameInput.accept($0) }
            .store(in: &cancellables)
        
        $email
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.viewModel.emailInput.accept($0) }
            .store(in: &cancellables)
        
        $password
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.viewModel.passwordInput.accept($0) }
            .store(in: &cancellables)
        
        $confirmPassword
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.viewModel.confirmPasswordInput.accept($0) }
            .store(in: &cancellables)
        
        // ViewModel
        viewModel.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.isLoading = $0 })
            .disposed(by: disposeBag)
        
        viewModel.isFormValid
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.isFormValid = $0 })
            .disposed(by: disposeBag)
        
        viewModel.nameValidation
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.nameValidation = $0 })
            .disposed(by: disposeBag)
        
        viewModel.emailValidation
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.emailValidation = $0 })
            .disposed(by: disposeBag)
        
        viewModel.passwordValidation
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.passwordValidation = $0 })
            .disposed(by: disposeBag)
        
        viewModel.confirmValidation
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.confirmValidation = $0 })
            .disposed(by: disposeBag)
        
        viewModel.passwordStrength
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.passwordStrength = $0 })
            .disposed(by: disposeBag)
        
        viewModel.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.errorText = message
                self?.showError = true
            })
            .disposed(by: disposeBag)
        
        viewModel.signUpSuccess
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] user in
                self?.signUpSuccessUser = user
            })
            .disposed(by: disposeBag)
    }
    
    func signUpTapped() { viewModel.signUpTapped() }
    
}
