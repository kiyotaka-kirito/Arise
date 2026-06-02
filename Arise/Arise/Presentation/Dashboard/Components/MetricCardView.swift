//
//  MetricCardView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import SwiftUI

// MARK: - MetricCardView
struct MetricCardView: View {
    
    // MARK: - Configuration
    let icon: String
    let title: String
    let value: String
    let color: Color
    var isAlert: Bool = false
    
    // MARK: - Animated State
    @State private var appeared: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Icon and Title row
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isAlert ? .red : color)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Alert indicator dot
                if isAlert {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(appeared ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                            value: appeared
                        )
                }
            }
            
            // Value
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(isAlert ? .red : .primary)
                .offset(y: appeared ? 0 : 10)
                .opacity(appeared ? 1 : 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ariseCardFallback)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(appeared ? 1 : 0.95)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
        
    }
}

// MARK: - Preview
#Preview {
    HStack {
        MetricCardView(
            icon: "heart.fill",
            title: "Heart Rate",
            value: "72 bpm",
            color: .pink
        )
        MetricCardView(
            icon: "heart.fill",
            title: "Heart Rate",
            value: "120 bpm",
            color: .pink,
            isAlert: true
        )
    }
    .padding()
}
