//
//  ListMetricView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import SwiftUI

struct ListMetricView: View {
    
    let icon: String
    let lablel: String
    let value: String
    var accentColor: Color = Color.arisePrimaryFallback
    var isLarge: Bool = false
    
    @State private var pulsing = false

    var body: some View {
        VStack(spacing: isLarge ? 8 : 4) {
            
            // Icon
            Image(systemName: icon)
                .font(.system(
                    size: isLarge ? 22 : 16,
                    weight: .semibold
                    )
                )
                .foregroundStyle(accentColor)
            
            // Live value
            Text(value)
                .font(isLarge
                      ? .system(size: 36, weight: .black, design: .rounded)
                      : .system(size: 22, weight: .bold, design: .rounded)
                )
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .scaleEffect(pulsing ? 1.04 : 1.0)
            
            // Label
            Text(lablel)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isLarge ? 20 : 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ariseCardFallback)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
        .onChange(of: value) { _, _ in
            withAnimation(.easeOut(duration: 0.15)) { pulsing = true }
            withAnimation(.easeIn(duration: 0.15).delay(0.15)) { pulsing = false }
        }
    }
    
}

#Preview {
    ListMetricView(icon: "heart", lablel: "Heart", value: "100")
}
