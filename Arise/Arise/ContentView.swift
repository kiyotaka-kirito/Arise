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
    private let disposeBag = DisposeBag()
    
    var body: some View {
        routeView(for: currentRoute)
            .onAppear {
                coordinator.currentRoute
                    .observe(on: MainScheduler.instance)
                    .subscribe { route in
                        currentRoute = route
                    }
                    .disposed(by: disposeBag)
            }
    }
    
    // MARK: - Route
    @ViewBuilder
    private func routeView(for route: AppRoute) -> some View {
        switch route {
        case .signIn, .onboarding:
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.pink)
                Text("Arise")
                    .font(.largeTitle.bold())
                Text("Your personal health companion")
                    .foregroundStyle(.secondary)
                Button("Enter App (Temp)") {
                    coordinator.navigate(to: .mainTab)
                }
                .buttonStyle(.borderedProminent)
            }
        
        case .mainTab:
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                Text("Architecture Complete!")
                    .font(.title.bold())
                Text("All layers connected successfully.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
        default:
            EmptyView()
        }
    }
    
}

#Preview {
    ContentView(coordinator: AppCoordinator(container: AppDependencyContainer()), container: AppDependencyContainer())
}
