//
//  SignInView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 03/06/2026.
//

import SwiftUI
import RxSwift
import Combine
import RxRelay

// MARK: - SignInView
struct SignInView: View {
    
    @StateObject private var wrapper: SignInViewModelWrapper
    let onSignInSuccess: (User) -> Void
    let onNavigateToSignUp: () -> Void
    
    init(
        viewModel: SignInViewModel,
        onSignInSuccess: @escaping (User) -> Void,
        onNavigateToSignUp: @escaping () -> Void
    ) {
        _wrapper = StateObject(
            wrappedValue: SignInViewModelWrapper(viewModel: viewModel)
        )
        self.onSignInSuccess = onSignInSuccess
        self.onNavigateToSignUp = onNavigateToSignUp
    }
    
    // MARK: - Animation States
    @State private var logoAppeared     = false
    @State private var formAppeared     = false
    @State private var buttonAppeared   = false
    
    var body: some View {
        ZStack {
            
            // Background gradient
            LinearGradient(
                colors: [
                    Color.arisePrimaryFallback.opacity(0.1),
                    Color.ariseBackgroundFallback,
                    Color.ariseBackgroundFallback
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    logoSection
                        .padding(.top, 60)
                        .padding(.bottom, 40)
                    
                    formSection
                        .padding(.horizontal, 28)
                    
                    signInButton
                        .padding(.horizontal, 28)
                        .padding(.top, 24)
                    
                    dividerSection
                        .padding(.horizontal, 28)
                        .padding(.vertical, 24)
                    
                    signUpPrompt
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear { runEntryAnimation() }
        .onChange(of: wrapper.signInSuccessUser) { _, user in
            guard let user = user else { return }
            onSignInSuccess(user)
        }
        .alert("Sign In Failed", isPresented: $wrapper.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(wrapper.errorText)
        }
    }
    
}

// MARK: - Components
extension SignInView {
    
    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.arisePrimaryFallback.opacity(0.15))
                    .frame(width: 88, height: 88)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.arisePrimaryFallback)
                    .scaleEffect(logoAppeared ? 1.0 : 0.3)
                    .opacity(logoAppeared ? 1.0 : 0)
            }
            .shadow(
                color: Color.arisePrimaryFallback.opacity(0.3),
                radius: 20, x: 0, y: 10
            )
            
            VStack(spacing: 4) {
                Text("Welcome Back")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .opacity(logoAppeared ? 1 : 0)
                    .offset(y: logoAppeared ? 0 : 16)
                
                Text("Sign in to continue your journey")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .opacity(logoAppeared ? 1 : 0)
                    .offset(y: logoAppeared ? 0 : 10)
            }
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 14) {
            
            AriseTextField(
                icon: "envelope",
                placeholder: "Email address",
                text: $wrapper.email,
                validation: wrapper.emailValidation,
                keyboardType: .emailAddress
            )
            
            AriseTextField(
                icon: "lock",
                placeholder: "Password",
                text: $wrapper.password,
                validation: wrapper.passwordValidation,
                isSecure: true
            )
            
            // Forgot password
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    // Implement
                }
                .font(.caption)
                .foregroundStyle(Color.arisePrimaryFallback)
            }
        }
        .opacity(formAppeared ? 1 : 0)
        .offset(y: formAppeared ? 0 : 24)
    }
    
    // MARK: - Sign In Button
    private var signInButton: some View {
        Button {
            wrapper.signInTapped()
        } label: {
            ZStack {
                if wrapper.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.1)
                } else {
                    HStack(spacing: 8) {
                        Text("Sign In")
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
        .opacity(buttonAppeared ? 1 : 0)
        .offset(y: buttonAppeared ? 0 : 16)
    }
    
    // MARK: - Divider
    private var dividerSection: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.secondary.opacity(0.2)).frame(height: 1)
            Text("or").font(.caption).foregroundStyle(.secondary)
            Rectangle().fill(Color.secondary.opacity(0.2)).frame(height: 1)
        }
    }
    
    // MARK: - Sign Up Prompt
    private var signUpPrompt: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button("Sign Up") {
                onNavigateToSignUp()
            }
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(Color.arisePrimaryFallback)
        }
    }
    
    // MARK: - Entry Animation
    private func runEntryAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            logoAppeared = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            formAppeared = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35)) {
            buttonAppeared = true
        }
    }
}

// MARK: - SignInViewModelWrapper
@MainActor
final class SignInViewModelWrapper: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var isFormValid: Bool = false
    @Published var emailValidation: ValidationState = .idle
    @Published var passwordValidation: ValidationState = .idle
    @Published var showError: Bool = false
    @Published var errorText: String = ""
    @Published var signInSuccessUser: User? = nil
    
    private let viewModel: SignInViewModel
    private var disposeBag = DisposeBag()
    private var cancellable = Set<AnyCancellable>()
    
    init(viewModel: SignInViewModel) {
        self.viewModel = viewModel
        bindToViewModel()
    }
    
    private func bindToViewModel() {
        
        $email
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.viewModel.emailInput.accept($0) }
            .store(in: &cancellable)
        
        $password
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.viewModel.passwordInput.accept($0) }
            .store(in: &cancellable)
        
        // ViewModel
        viewModel.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.isLoading = $0 })
            .disposed(by: disposeBag)
        
        viewModel.isFormValid
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.isFormValid = $0 })
            .disposed(by: disposeBag)
        
        viewModel.emailValidation
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.emailValidation = $0 })
            .disposed(by: disposeBag)
        
        viewModel.passwordValidation
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.passwordValidation = $0 })
            .disposed(by: disposeBag)
        
        viewModel.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.errorText = message
                self?.showError = true
            })
            .disposed(by: disposeBag)
        
        viewModel.signInSuccess
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] user in
                self?.signInSuccessUser = user
            })
            .disposed(by: disposeBag)
    }
    
    func signInTapped() { viewModel.signInTapped() }
}
