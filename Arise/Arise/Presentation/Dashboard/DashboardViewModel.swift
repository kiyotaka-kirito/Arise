//
//  DashboardViewModel.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - DashboardViewModel
final class DashboardViewModel {
    
    // MARK: - Dependencies
    private let getCurrentUserUseCase: GetCurrentUserUseCaseProtocol
    private let fetchHealthSummaryUseCase: FetchHealthSummaryUseCaseProtocol
    private let bluetoothService: BluetoothServiceProtocol
    
    // MARK: - Outputs
    let currentUser = BehaviorRelay<User?>(value: nil)
    let healthSummary = BehaviorRelay<HealthSummary?>(value: nil)
    let isLoading = BehaviorRelay<Bool>(value: false)
    let errorMessage = PublishRelay<String>()
    let bluetoothState = BehaviorRelay<BluetoothState>(value: .unknown)
    
    // MARK: - Memory Management
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(
        getCurrentUserUseCase: GetCurrentUserUseCaseProtocol,
        fetchHealthSummaryUseCase: FetchHealthSummaryUseCaseProtocol,
        bluetoothService: BluetoothServiceProtocol
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.fetchHealthSummaryUseCase = fetchHealthSummaryUseCase
        self.bluetoothService = bluetoothService
        setupBluetoothObserver()
    }
    
    // MARK: - Inputs
    func viewDidLoad() {
        loadDashboardData()
    }
    
    func refresh() {
        loadDashboardData()
    }
    
    // MARK: - Logic
    private func loadDashboardData() {
        isLoading.accept(true)
        
        getCurrentUserUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] user in
                    guard let self = self else { return }
                    self.currentUser.accept(user)
                    self.loadHealthSummary(for: user.id)
                }, onError: { [weak self] error in
                    self?.isLoading.accept(false)
                    self?.errorMessage.accept(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func loadHealthSummary(for userId: String) {
        fetchHealthSummaryUseCase.execute(for: userId)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] summary in
                    self?.healthSummary.accept(summary)
                    self?.isLoading.accept(false)
                },
                onFailure: { [weak self] error in
                    self?.isLoading.accept(false)
                    self?.errorMessage.accept(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func setupBluetoothObserver() {
        bluetoothService.bluetoothState
            .observe(on: MainScheduler.instance)
            .bind(to: bluetoothState)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:    return "Good Morning"
        case 12..<17:   return "Good Afternoon"
        case 17..<21:   return "Good Evening"
        default:        return "Good Night"
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
}
