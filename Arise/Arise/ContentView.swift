//
//  ContentView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import SwiftUI
import RxSwift

struct ContentView: View {
    
    // MARK: - Dependencies
    let coordinator: AppCoordinator
    let container: AppDependencyContainer
    
    // MARK: - State
    @State private var showSignUp = false
    @State private var currentRoute: AppRoute = .signIn
    @State private var selectedTab: Int = 0
    private let disposeBag = DisposeBag()
    
    var body: some View {
        Group {
            switch currentRoute {
            case .signIn, .onboarding:
                authFlow
                
            case .mainTab:
                mainTabView
                
            default:
                mainTabView
            }
        }
        .onAppear {
            coordinator.currentRoute
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { route in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentRoute = route
                    }
                })
                .disposed(by: disposeBag)
        }
        
    }
    
}

// MARK: - Components
extension ContentView {
    
    // MARK: - Auth Flow
    @ViewBuilder
    private var authFlow: some View {
        if showSignUp {
            SignUpView(
                viewModel: container.makeSignUpViewModel(),
                onSignUpSuccess: { user in handleAuthSuccess(user: user)},
                onNavigateToSignIn: {
                    withAnimation(.spring(response: 0.4)) { showSignUp = false }
                }
            )
            .transition(
                .asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                )
            )
        } else {
            SignInView(
                viewModel: container.makeSignInViewModel(),
                onSignInSuccess: { user in handleAuthSuccess(user: user)},
                onNavigateToSignUp: {
                    withAnimation(.spring(response: 0.4)) { showSignUp = true }
                }
            )
            .transition(
                .asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                )
            )
        }
        
    }
    
    // MARK: - Main Tab View
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: container.makeDashboardViewModel())
                .tabItem {
                    Label("Dashboard", systemImage: "heart.fill")
                }
                .tag(0)
            
            WorkoutView(
                viewModel: container.makeWorkoutViewModel(),
                container: container
            )
            .tabItem {
                Label("Workout", systemImage: "figure.run")
            }
            .tag(1)
            
            ProfileView(
                viewModel: container.makeProfileViewModel(),
                onSignOut: { coordinator.handleSignOut() }
            )
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(2)
        }
        .tint(Color.arisePrimaryFallback)
    }
    
    // MARK: - Auth Success Handler
    private func handleAuthSuccess(user: User) {
        _ = container.saveUserToRealm(user)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            coordinator.navigate(to: .mainTab)
        }
    }
}

#Preview {
    ContentView(
        coordinator: AppCoordinator(container: AppDependencyContainer()),
        container: AppDependencyContainer()
    )
}
