//
//  AppDependencyContainer.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RealmSwift
import RxSwift

// MARK: - AppDependencyContainer
final class AppDependencyContainer {
    
    // MARK: - Shared Instance (Singletons within the container)
    
    // MARK: - Storage
    private let realmConfiguration: Realm.Configuration
    
    // MARK: - Services
    private lazy var authService: AuthServiceProtocol = {
        // KeychainAuthService()
        FirebaseAuthService()
    }()
    
    private lazy var locationService: LocationServiceProtocol = {
        CoreLocationService()
    }()
    
    private lazy var bluetoothService: BluetoothServiceProtocol = {
        CoreBluetoothService()
    }()
    
    // MARK: - Repositories
    private lazy var userRepository: UserRepositoryProtocol = {
        RealmUserRepository(configuration: realmConfiguration)
    }()
    
    private lazy var healthDataRepository: HealthRepositoryProtocol = {
        RealmHealthRepository(configuration: realmConfiguration)
    }()
    
    private lazy var workoutRepository: WorkoutRepositoryProtocol = {
        RealmWorkoutRepositroy(configuration: realmConfiguration)
    }()
    
    // MARK: - Init
    init() {
        self.realmConfiguration = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 { }
            }
        )
    }
    
    // MARK: - UseCase Factory Methods
    private func makeSignInUseCase() -> SignInUseCaseProtocol {
        SignInUseCase(authService: authService, userRepository: userRepository)
    }
    
    private func makeGetCurrentUserUseCase() -> GetCurrentUserUseCaseProtocol {
        GetCurrentUserUseCase(authService: authService, userRepository: userRepository)
    }
    
    private func makeStartWorkoutUseCase() -> StartWorkoutUseCaseProtocol {
        StartWorkoutUseCase(workoutRepository: workoutRepository, locationService: locationService)
    }
    
    private func makeStopWorkoutUseCase() -> StopWorkoutUseCaseProtocol {
        StopWorkoutUseCase(workoutRepository: workoutRepository, locationService: locationService)
    }
    
    private func makeFetchWorkoutHistoryUseCase() -> FetchWorkoutHistoryUseCaseProtocol {
        FetchWorkoutHistoryUseCase(workoutRepository: workoutRepository)
    }
    
    private func makeFetchHealthSummaryUseCase() -> FetchHealthSummaryUseCaseProtocol {
        FetchHealthSummaryUseCase(healthRepository: healthDataRepository, workoutRepository: workoutRepository)
    }
    
    // MARK: - ViewModel Factory Methods
    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            getCurrentUserUseCase: makeGetCurrentUserUseCase(),
            fetchHealthSummaryUseCase: makeFetchHealthSummaryUseCase(),
            bluetoothService: bluetoothService
        )
    }
    
    func makeWorkoutViewModel() -> WorkoutViewModel {
        WorkoutViewModel(
            startWorkoutUseCase: makeStartWorkoutUseCase(),
            stopWorkoutUseCase: makeStopWorkoutUseCase(),
            locationService: locationService,
            bluetoothService: bluetoothService
        )
    }
    
    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            getCurrentUserUseCase: makeGetCurrentUserUseCase(),
            userRepository: userRepository,
            authService: authService
        )
    }
    
    func makeSignInViewModel() -> SignInViewModel {
        SignInViewModel(signInUseCase: makeSignInUseCase())
    }
    
    func makeSignUpViewModel() -> SignUpViewModel {
        SignUpViewModel(
            authService: authService,
            userRepository: userRepository
        )
    }
    
    // MARK: - Bluetooth
    func makeBluetoothViewModel() -> BluetoothViewModel {
        BluetoothViewModel(bluetoothService: bluetoothService)
    }
    
    // MARK: - Realm Save Helper
    func saveUserToRealm(_ user: User) -> Completable {
        userRepository.saveUser(user)
    }
    
    // MARK: - Development Helper
    private let disposeBag = DisposeBag()
    
    func signInMockUser(completion: @escaping (AppRoute) -> Void) {
        let credentials = AutAuthCredentials(
            email: "kiri@gmail.com",
            password: "password123"
        )
        
        let signInUseCase = makeSignInUseCase()
        
        signInUseCase.execute(with: credentials)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { user in
                    self.userRepository.saveUser(user)
                        .subscribe(
                            onCompleted: {
                                completion(.mainTab)
                            },
                            onError: { error in
                                completion(.mainTab)
                            }
                        )
                        .disposed(by: self.disposeBag)
                },
                onFailure: { _ in
                    completion(.mainTab)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
