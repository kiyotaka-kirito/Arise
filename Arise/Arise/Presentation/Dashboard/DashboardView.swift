//
//  DashboardView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import SwiftUI
import RxSwift
import Combine

// MARK: - DashboardView
struct DashboardView: View {
    
    // MARK: - ViewModel
    @StateObject private var viewModel: DashboardViewModelWrapper
    
    // MARK: - Init
    init(viewModel: DashboardViewModel) {
        _viewModel = StateObject(
            wrappedValue: DashboardViewModelWrapper(viewModel: viewModel)
        )
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.ariseBackgroundFallback
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadinView
                } else {
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .onAppear { viewModel.viewDidLoad() }
        }
    }
}

//#Preview {
//    DashboardView()
//}

// MARK: - Components
extension DashboardView {
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                headerSection
                vitalsSection
                stepsSection
                quickStatsSection
                recentWorkoutsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .refreshable {
            viewModel.refresh()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(viewModel.userName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(viewModel.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Profile button
            Button {
                // Navigate to profile
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.arisePrimaryFallback, Color.arisePrimaryFallback.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Text(viewModel.userInitials)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

        }
        .padding(.top, 16)
    }
    
    
    // MARK: - Vitials Section (Heart Rate And Blood Oxygen)
    private var vitalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Vitals")

            HStack(spacing: 12) {
                MetricCardView(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    value: viewModel.heartRateDisplay,
                    color: .pink,
                    isAlert: viewModel.isHeartRateAlert
                )

                MetricCardView(
                    icon: "lungs.fill",
                    title: "Blood O₂",
                    value: viewModel.bloodOxygenDisplay,
                    color: .blue,
                    isAlert: viewModel.isBloodOxygenAlert
                )
            }
        }
    }
    
    // MARK: - Steps Section
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Activity")
            StepsProgressView(steps: viewModel.todaySteps)
        }
    }
    
    // MARK: - Quick Stats Section (Calories And Sleep)
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            MetricCardView(
                icon: "flame.fill",
                title: "Calories",
                value: viewModel.caloriesDisplay,
                color: .orange
            )
            
            MetricCardView(
                icon: "moon.fill",
                title: "Sleep",
                value: viewModel.sleepDisplay,
                color: .indigo
            )
        }
    }
    
    // MARK: - Recent Workouts Section
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Recent Workouts")
            
            if viewModel.recentWorkouts.isEmpty {
                emptyWorkoutsView
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentWorkouts) { session in
                        WorkoutHistoryRowView(session: session)
                        
                        if session.id != viewModel.recentWorkouts.last?.id {
                            Divider()
                                .padding(.leading, 62)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.ariseCardFallback)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                )
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyWorkoutsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("No workouts yet")
                .font(.subheadline)
                .fontWeight(.medium)
            Text("Start your first workout to see it here")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Loading View
    private var loadinView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading your health data...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Section Header Helper
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
    }
}

// MARK: - DashboardViewModelWrapper
@MainActor
final class DashboardViewModelWrapper: ObservableObject {
    
    // MARK: - Published State
    @Published var isLoading: Bool = false
    @Published var userName: String = ""
    @Published var userInitials: String = ""
    @Published var heartRateDisplay: String = "-- bpm"
    @Published var bloodOxygenDisplay: String = "-- %"
    @Published var isHeartRateAlert: Bool = false
    @Published var isBloodOxygenAlert: Bool = false
    @Published var todaySteps: Double = 0
    @Published var caloriesDisplay: String = "-- kcal"
    @Published var sleepDisplay: String = "-- h"
    @Published var recentWorkouts: [WorkoutSession] = []
    
    // MARK: - ViewModel
    var greeting: String { viewModel.greeting }
    var formattedDate: String { viewModel.formattedDate }
    
    // MARK: - Private
    private let viewModel: DashboardViewModel
    private var disposeBag = DisposeBag()
    
    // MARK: - Init
    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
        bindToViewModel()
    }
    
    // MARK: - Bind RxSwift to SwiftUI
    private func bindToViewModel() {
        
        // isLoading
        viewModel.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] value in
                self?.isLoading = value
            }
            .disposed(by: disposeBag)
        
        // User data
        viewModel.currentUser
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] user in
                guard let user = user else { return }
                self?.userName = user.fullName.components(separatedBy: " ").first ?? ""
                let parts = user.fullName.components(separatedBy: " ")
                let initials = parts.compactMap { $0.first }.prefix(2)
                self?.userInitials = String(initials).uppercased()
            }
            .disposed(by: disposeBag)
        
        // Health summary
        viewModel.healthSummary
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] summary in
                guard let self = self, let summary = summary else { return }
                self.updateHealthDisplays(from: summary)
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - Update Helpers
    private func updateHealthDisplays(from summary: HealthSummary) {
        
        // Heart rate
        if let hr = summary.latestHeartRate {
            heartRateDisplay = hr.formattedValue
            isHeartRateAlert = !hr.isWithinHealthyRange
        }
        
        // Blood oxygen
        if let bo = summary.latestBloodOxygen {
            bloodOxygenDisplay = bo.formattedValue
            isBloodOxygenAlert = !bo.isWithinHealthyRange
        }
        
        // Steps
        todaySteps = summary.todaySteps
        
        // Calories
        caloriesDisplay = "\(Int(summary.todayCalories)) kcal"
        
        // Sleep
        if let sleep = summary.latestSleepDuration {
            let hours = sleep.value / 60
            sleepDisplay = "\(hours.rounded(toPlaces: 1)) h"
        }
    }
    
    // MARK: - Forward to ViewModel
    func viewDidLoad() { viewModel.viewDidLoad() }
    func refresh() { viewModel.refresh() }
}

