//
//  AppContainer.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RxSwift

// MARK: - AppRoute
enum AppRoute: Equatable {
    case onboarding
    case signIn
    case mainTab
    case workout(type: WorkoutType)
    case workoutSummary(session: WorkoutSession)
    case profile
}

// MARK: - AppCoordinator
final class AppCoordinator {
    
    // MARK: - Dependencies
    private let container: AppDependencyContainer
    
    // MARK: - Navigation State
    let currentRoute = BehaviorSubject<AppRoute>(value: .signIn)
    
    // MARK: - Memory Management
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(container: AppDependencyContainer) {
        self.container = container
    }
    
    // MARK: - Navigation Methods
    func start() {
        navigate(to: .signIn)
    }
    
    func navigate(to route: AppRoute) {
        currentRoute.onNext(route)
    }
    
    func navigateToMainTab() {
        navigate(to: .mainTab)
    }
    
    func handleSignOut() {
        navigate(to: .signIn)
    }
    
}
