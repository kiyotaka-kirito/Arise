//
//  ProfileView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 03/06/2026.
//

import SwiftUI
import RxSwift
import Combine

// MARK: - ProfileView
struct ProfileView: View {
    
    @StateObject private var wrapper: ProfileViewModelWrapper
    let onSignOut: () -> Void
    
    init(viewModel: ProfileViewModel, onSignOut: @escaping () -> Void) {
        _wrapper = StateObject(
            wrappedValue: ProfileViewModelWrapper(viewModel: viewModel)
        )
        self.onSignOut = onSignOut
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ariseBackgroundFallback.ignoresSafeArea()
                
                if wrapper.isLoading {
                    loadingView
                } else if let user = wrapper.currentUser {
                    profileContent(user: user)
                } else {
                    emptyStateView
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $wrapper.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(wrapper.errorText)
            }
            .alert("Saved!", isPresented: $wrapper.showSaveSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your profile has been updated.")
            }
            .onAppear { wrapper.viewDidLoad() }
        }
    }
}

// MARK: - Components
extension ProfileView {
    
    // MARK: - Profile Content
    private func profileContent(user: User) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                
                // Header
                ProfileHeaderView(user: user)
                    .padding(.horizontal, 20)
                
                // Health Stats Card
                healthStatsCard(user: user)
                
                // Edit Profile Card
                editProfileCard
                
                // Sign Out
                signOutButton
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Health Stats Card
    private func healthStatsCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            
            sectionHeader("Health Stats")
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                ProfileStatRowView(
                    icon: "scalemass.fill",
                    label: "BMI",
                    value: wrapper.bmiDisplay,
                    accentColor: bmiColor(user.bmiCategory)
                )
                Divider().padding(.leading, 52)
                
                ProfileStatRowView(
                    icon: "person.fill",
                    label: "Age",
                    value: wrapper.ageDisplay,
                    accentColor: .blue
                )
                Divider().padding(.leading, 52)
                
                ProfileStatRowView(
                    icon: "arrow.up.and.down",
                    label: "Height",
                    value: wrapper.heightDisplay,
                    accentColor: .teal
                )
                Divider().padding(.leading, 52)
                
                ProfileStatRowView(
                    icon: "scalemass",
                    label: "Weight",
                    value: wrapper.weightDisplay,
                    accentColor: .orange
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.ariseCardFallback)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Edit Profile Card
    private var editProfileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            sectionHeader("Edit Profile")
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                
                // Name Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Full Name")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    TextField("Your name", text: $wrapper.editedFullName)
                        .font(.subheadline)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.secondary.opacity(0.08))
                        )
                }
                
                // Weight Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weight (kg)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    TextField(
                        "Weight in kg",
                        value: $wrapper.editedWeight,
                        format: .number.precision(.fractionLength(1))
                    )
                    .keyboardType(.decimalPad)
                    .font(.subheadline)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.08))
                    )
                }
                
                // Height Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Height (cm)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    TextField(
                        "Height in cm",
                        value: $wrapper.editedHeight,
                        format: .number.precision(.fractionLength(0))
                    )
                    .keyboardType(.decimalPad)
                    .font(.subheadline)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.08))
                    )
                }
                
                // Save Button
                Button {
                    wrapper.saveChanges()
                } label: {
                    HStack {
                        if wrapper.isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                                .fontWeight(.bold)
                            Text("Save Changes")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.arisePrimaryFallback)
                            .shadow(
                                color: Color.arisePrimaryFallback.opacity(0.35),
                                radius: 10, x: 0, y: 5
                            )
                    )
                }
                .disabled(wrapper.isLoading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.ariseBackgroundFallback)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button {
            wrapper.signOut()
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red.opacity(0.1))
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Loading And Empty
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.2)
            Text("Loading profile...")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 56)).foregroundStyle(.secondary)
            Text("Profile unavailable")
                .font(.headline)
            Text("Please sign in to view your profile.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Helpers
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
    }
    
    private func bmiColor(_ category: BMICategory) -> Color {
        switch category {
        case .underweight:  return .blue
        case .normal:       return .green
        case .overweight:   return .orange
        case .obese:        return .red
        }
    }
}

// MARK: - ProfileViewModelWrapper
@MainActor
final class ProfileViewModelWrapper: ObservableObject {
    
    @Published var currentUser: User? = nil
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorText: String = ""
    @Published var showSaveSuccess: Bool = false
    @Published var editedFullName: String = ""
    @Published var editedWeight: Double = 0
    @Published var editedHeight: Double = 0
    
    var bmiDisplay: String { viewModel.bmiDisplay }
    var ageDisplay: String { viewModel.ageDisplay }
    var heightDisplay: String { viewModel.heightDisplay }
    var weightDisplay: String { viewModel.weightDisplay }
    
    private let viewModel: ProfileViewModel
    private var disposeBag = DisposeBag()
    private let onSignOut: (() -> Void)?
    
    init(viewModel: ProfileViewModel, onSignOut: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSignOut = onSignOut
        bindToViewModel()
    }
    
    private func bindToViewModel() {
        
        viewModel.currentUser
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.currentUser = $0 })
            .disposed(by: disposeBag)
        
        viewModel.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.isLoading = $0 })
            .disposed(by: disposeBag)
        
        viewModel.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.errorText = message
                self?.showError = true
            })
            .disposed(by: disposeBag)
        
        viewModel.saveSuccess
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.showSaveSuccess = true
            })
            .disposed(by: disposeBag)
        
        viewModel.signedOut
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.onSignOut?()
            })
            .disposed(by: disposeBag)
        
        // Sync editable fields
        viewModel.editedFullName
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.editedFullName = $0 })
            .disposed(by: disposeBag)
        
        viewModel.editedWeight
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.editedWeight = $0 })
            .disposed(by: disposeBag)
        
        viewModel.editedHeight
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.editedHeight = $0 })
            .disposed(by: disposeBag)
    }
    
    // Forward actions to ViewModel
    func viewDidLoad() { viewModel.viewDidLoad() }
    func saveChanges() { viewModel.saveChanges() }
    func signOut() { viewModel.signOut() }
    
}
