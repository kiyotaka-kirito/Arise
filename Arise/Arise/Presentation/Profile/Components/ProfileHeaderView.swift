//
//  ProfileHeaderView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 03/06/2026.
//

import SwiftUI

struct ProfileHeaderView: View {
    
    let user: User
    
    var body: some View {
        VStack(spacing: 14) {
            
            // Avatar circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.arisePrimaryFallback, Color.arisePrimaryFallback.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(
                        color: Color.arisePrimaryFallback.opacity(0.4),
                        radius: 16, x: 0, y: 8
                    )
                
                // User initials
                Text(initials(from: user.fullName))
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.white)
            }
            
            // Name and Email
            VStack(spacing: 4) {
                Text(user.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Quick stats row
            HStack(spacing: 0) {
                statPill(value: "\(user.age)", label: "Age")
                Divider().frame(height: 32)
                statPill(value: "\(Int(user.heightInCm))cm", label: "Height")
                Divider().frame(height: 32)
                statPill(value: "\(user.weightInKg)kg", label: "Weight")
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.ariseCardFallback)
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Helpers
    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    
    private func initials(from name: String) -> String {
        let parts = name.components(separatedBy: " ")
        let letters = parts.compactMap { $0.first }.prefix(2)
        return String(letters).uppercased()
    }
    
}

#Preview {
    ProfileHeaderView(user: User(fullName: "Kiri", email: "kiri@gmail.com", dateOfBirth: Date(), gender: .male, heightInCm: 170.00, weightInKg: 75.6))
}
