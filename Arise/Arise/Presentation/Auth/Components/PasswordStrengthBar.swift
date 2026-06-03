//
//  PasswordStrengthBar.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 03/06/2026.
//

import SwiftUI

struct PasswordStrengthBar: View {
    
    let strength: PasswordStrength
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            // Segmented progress bar
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(segmentColor(for: index))
                        .frame(height: 4)
                        .animation(
                            .spring(response: 0.4).delay(Double(index) * 05),
                            value: strength
                        )
                }
            }
            
            // Label
            if strength != .empty {
                HStack {
                    Spacer()
                    Text(strength.label)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(strength.color)
                        .transition(.opacity)
                        .animation(.easeInOut, value: strength)
                }
            }
        }
    }
    
    // Each segment lights up based on strength level
    private func segmentColor(for index: Int) -> Color {
        let filledSegments: Int
        switch strength {
        case .empty:        filledSegments = 0
        case .weak:         filledSegments = 1
        case .fair:         filledSegments = 2
        case .strong:       filledSegments = 3
        case .veryStrong:   filledSegments = 4
        }
        return index < filledSegments
            ? strength.color
            : Color.secondary.opacity(0.2)
    }
}
