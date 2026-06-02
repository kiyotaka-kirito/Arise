//
//  WorkoutView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import SwiftUI
import RxSwift
import Combine

// MARK: - WorkoutView
struct WorkoutView: View {
    
    @StateObject private var wrapper: WorkoutViewModelWrapper
    
    init(viewModel: WorkoutViewModel) {
        _wrapper = StateObject(
            wrappedValue: WorkoutViewModelWrapper(viewModel: viewModel)
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ariseBackgroundFallback.ignoresSafeArea()
                
                if wrapper.isTracking {
                    activeWorkoutView
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                } else {
                    preWorkoutView
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: wrapper.isTracking)
            .navigationBarHidden(true)
            .alert("Error", isPresented: $wrapper.showError) {
                Button("Ok", role: .cancel) {}
            } message: {
                Text(wrapper.errorText)
            }
        }
    }
}

// MARK: - Components
extension WorkoutView {
    
    // MARK: - Pre-Workout: Activity Picker
    private var preWorkoutView: some View {
        VStack(spacing: 24) {
            
            // Header
            VStack(spacing: 6) {
                Text("New Workout")
                    .font(.largeTitle)
                    .fontWeight(.black)
                Text("What are you doing today?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            
            WorkoutTypePickerView(selectedType: $wrapper.selectedWorkoutType)
            
            Spacer()
            
            // Start button
            WorkoutControlButton(style: .start) {
                wrapper.startWorkout()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Active Workout: Live Stats
    private var activeWorkoutView: some View {
        VStack(spacing: 0) {
            
            // Status bar area
            activeWorkHeader
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    
                    // Big Timer
                    timerSection
                    
                    // Live Metrics Grid
                    metricGrid
                    
                    // Heart Rate Zone Banner
                    if wrapper.currentHeartRate > 0 {
                        heartRateZoneRunner
                    }
                    
                    Spacer().frame(height: 16)
                }
                .padding(.horizontal, 20)
            }
            
            // Bottom Controls
            workoutControls
        }
    }
    
    // MARK: - Active Header
    private var activeWorkHeader: some View {
        HStack {
            // Activity type badge
            HStack(spacing: 8) {
                Image(systemName: wrapper.selectedWorkoutType.iconName)
                    .font(.system(size: 14, weight: .semibold))
                Text(wrapper.selectedWorkoutType.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Color.arisePrimaryFallback)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.arisePrimaryFallback.opacity(0.12))
            )
            
            Spacer()
            
            // Live indicator dot
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 4)
                            .scaleEffect(wrapper.isTracking ? 1.8 : 1.0)
                            .opacity(wrapper.isTracking ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.0).repeatForever(autoreverses: false),
                                value: wrapper.isTracking
                            )
                    )
                
                Text("LIVE")
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    // MARK: - Timer Section
    private var timerSection: some View {
        VStack(spacing: 4) {
            Text(wrapper.elapsedTime)
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .monospacedDigit()
            
            Text(wrapper.isPaused ? "PAUSED" : "ELAPSED TIME")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(wrapper.isPaused ? .orange : .secondary)
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.ariseCardFallback)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Metric Grid
    private var metricGrid: some View {
        VStack(spacing: 12) {
            
            // Distance (large, top)
            ListMetricView(
                icon: "map.fill",
                lablel: "DISTANCE",
                value: wrapper.distanceDisplay,
                accentColor: Color.arisePrimaryFallback,
                isLarge: true
            )
            
            // HeartRate and Speed
            HStack(spacing: 12) {
                ListMetricView(
                    icon: "heart.fill",
                    lablel: "BPM",
                    value: wrapper.heartRateDisplay,
                    accentColor: .pink
                )
                
                ListMetricView(
                    icon: "speedometer",
                    lablel: "SPEED",
                    value: wrapper.speedDisplay,
                    accentColor: .orange
                )
            }
        }
    }
    
    // MARK: - Heart Rate Zone Runner
    private var heartRateZoneRunner: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.pink)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Heart Rate Zone")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(wrapper.heartRateZoneName)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Text("\(Int(wrapper.currentHeartRate)) bpm")
                .font(.headline)
                .fontWeight(.black)
                .foregroundStyle(.pink)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.pink.opacity(0.1))
        )
    }
    
    // MARK: - Bottom Controls
    private var workoutControls: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack(spacing: 12) {
                // Pause / Resume
                WorkoutControlButton(style: wrapper.isPaused ? .resume : .pause
                ) {
                    wrapper.togglePause()
                }
                
                // Stop
                WorkoutControlButton(style: .stop) {
                    wrapper.stopWorkout()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .padding(.top, 8)
        }
        .background(Color.ariseBackgroundFallback)
    }
    
}

// MARK: - WorkoutViewModelWrapper
@MainActor
final class WorkoutViewModelWrapper:  ObservableObject {
    
    @Published var isTracking: Bool = false
    @Published var isPaused: Bool = false
    @Published var elapsedTime: String = "00:00"
    @Published var currentHeartRate: Double = 0
    @Published var distanceDisplay: String = "0.00 km"
    @Published var speedDisplay: String = "0.00 km/h"
    @Published var heartRateZoneName: String = "Rest"
    @Published var selectedWorkoutType: WorkoutType = .running
    @Published var showError: Bool = false
    @Published var errorText: String = ""
    
    private let placeholderUserId = "user_001"
    
    private let viewModel: WorkoutViewModel
    private var disposeBag = DisposeBag()
    
    init (viewModel: WorkoutViewModel) {
        self.viewModel = viewModel
        bindToViewModel()
    }
    
    private func bindToViewModel() {
        
        viewModel.isTracking
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.isTracking = $0 })
            .disposed(by: disposeBag)
        
        viewModel.isPaused
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.isPaused = $0 })
            .disposed(by: disposeBag)
        
        viewModel.elapsedTime
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.elapsedTime = $0 })
            .disposed(by: disposeBag)
        
        viewModel.currentHeartRate
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] bpm in
                self?.currentHeartRate = bpm
                self?.heartRateZoneName = HeartRateZone(bpm: bpm).displayName
            })
            .disposed(by: disposeBag)
        
        viewModel.currentDistance
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.distanceDisplay = self?.viewModel.distanceDisplay ?? ""
            })
            .disposed(by: disposeBag)
        
        viewModel.currentSpeed
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.speedDisplay = self?.viewModel.speedDisplay ?? ""
            })
            .disposed(by: disposeBag)
        
        viewModel.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.errorText = message
                self?.showError = true
            })
            .disposed(by: disposeBag)
    }
    
    func startWorkout() {
        viewModel.startWorkout(
            type: selectedWorkoutType,
            userId: placeholderUserId
        )
    }
    
    func togglePause() {
        isPaused ? viewModel.resumeWorkout() : viewModel.pauseWorkout()
    }
    
    func stopWorkout() {
        viewModel.stopWorkout()
    }
    
    var heartRateDisplay: String {
        currentHeartRate > 0 ? "\(Int(currentHeartRate))" : "--"
    }
    
}
