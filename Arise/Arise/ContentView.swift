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
    @State private var currentRoute: AppRoute = .signIn
    @State private var selectedTab: Int = 0
    private let disposeBag = DisposeBag()
    
    var body: some View {
        Group {
            switch currentRoute {
            case .signIn, .onboarding:
                signInPlaceholder
                
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
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentRoute = route
                    }
                })
                .disposed(by: disposeBag)
        }
        
    }
    
}

// MARK: - Components
extension ContentView {
    
    // MARK: - Sign In Placeholder
    private var signInPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.arisePrimaryFallback.opacity(0.15),
                    Color.ariseBackgroundFallback
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.arisePrimaryFallback.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.arisePrimaryFallback)
                    }
                    
                    Text("Arise")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(Color.arisePrimaryFallback)
                    
                    Text("Your personal health companion")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Button
                VStack(spacing: 12) {
                    Button {
                        container.signInMockUser { route in
                            coordinator.navigate(to: route)
                        }
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.arisePrimaryFallback)
                                    .shadow(
                                        color: Color.arisePrimaryFallback.opacity(0.4),
                                        radius: 16, x: 0, y: 8
                                    )
                            )
                    }
                    
                    Text("Real auth flow added in next milestone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
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
            
            WorkoutView(viewModel: container.makeWorkoutViewModel())
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
}

#Preview {
    ContentView(
        coordinator: AppCoordinator(container: AppDependencyContainer()),
        container: AppDependencyContainer()
    )
}
