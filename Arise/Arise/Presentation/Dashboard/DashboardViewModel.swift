//
//  DashboardViewModel.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import RxSwift

// MARK: - DashboardViewModel
final class DashboardViewModel {
    
    // MARK: - Dependencies
    private let getCurrentUserUseCase: GetCurrentUserUseCaseProtocol
    private let fetchHealthSummaryUseCase: FetchHealthSummaryUseCaseProtocol
    private let bluetoothService: BluetoothServiceProtocol
    
    // MARK: - Outputs
    let currentUser = BehaviorSubject<User?>(value: nil)
    let healthSummary = BehaviorSubject<HealthSummary?>(value: nil)
    let isLoading = BehaviorSubject<Bool>(value: false)
    let errorMessage = PublishSubject<String>()
    
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
    }
    
    // MARK: - Inputs
    func viewDidLoad() {
        loadDashboardData()
    }
    
    // MARK: - Logic
    private func loadDashboardData() {
        
    }
    
}
