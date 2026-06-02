//
//  StepsProgressView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import SwiftUI

// MARK: - StepsProgressView
struct StepsProgressView: View {
    
    let steps: Double
    let goal: Double = 10_000
    
    @State private var animatedProgress: Double = 0
    
    private var progress: Double {
        min(steps / goal, 1.0)
    }
    
    private var progressColor: Color {
        switch progress {
        case ..<0.3:    return Color(red: 0.38, green: 0.36, blue: 0.96)
        case ..<0.7:    return Color(red: 0.20, green: 0.60, blue: 0.96)
        default:        return Color(red: 0.18, green: 0.80, blue: 0.44)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Header row
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .foregroundStyle(progressColor)
                        .font(.system(size: 18, weight: .semibold))
                    Text("Steps Today")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Step count and Goal
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(steps.formatted(.number.precision(.fractionLength(0))))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(progressColor)
                    Text("/ \(Int(goal))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 12)
                    
                    // Filled progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [progressColor.opacity(0.7), progressColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * animatedProgress,
                            height: 12
                        )
                        // Shimmer effect
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                }
            }
            .frame(height: 12)
            
            // Percentage label
            Text("\(Int(progress * 100))% of daily goal")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ariseCardFallback)
                .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: steps) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = min(newValue / goal, 1.0)
            }
        }
        
    }
}

// MARK: - Preview
#Preview {
    VStack {
        StepsProgressView(steps: 8240)
        StepsProgressView(steps: 10500)
    }
    .padding()
}

