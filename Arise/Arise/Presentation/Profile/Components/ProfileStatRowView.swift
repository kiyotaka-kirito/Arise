//
//  ProfileStatRowView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 03/06/2026.
//

import SwiftUI

struct ProfileStatRowView: View {
    
    let icon: String
    let label: String
    let value: String
    var accentColor: Color = Color.arisePrimaryFallback
    
    var body: some View {
        HStack(spacing: 14) {
            
            // Icon badge
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    ProfileStatRowView(icon: "heart", label: "Heart", value: "0")
}
