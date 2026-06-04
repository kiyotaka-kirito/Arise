//
//  PeripheralRowView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 04/06/2026.
//

import SwiftUI

struct PeripheralRowView: View {
    
    let device: PeripheralDevice
    let signalLabel: String
    let signalColor: Color
    let isConnecting: Bool
    let isConnected: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            
            // Device icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: isConnected
                      ? "checkmark.circle.fill"
                      : "dot.radiowaves.left.and.right")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
            }
            
            // Device info
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 6) {
                    // Signal strength dot
                    Circle()
                        .fill(signalColor)
                        .frame(width: 6, height: 6)
                    
                    Text(signalLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(".")
                        .foregroundStyle(.secondary)
                    
                    Text("\(device.signalStrength) dBm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Action Button
            if isConnecting {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(width: 64)
            } else if isConnected {
                Button("Disconnect") {
                    onDisconnect()
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Color.red.opacity(0.1))
                )
            } else {
                Button("Connect") {
                    onConnect()
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.arisePrimaryFallback)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Color.arisePrimaryFallback.opacity(0.1))
                )
            }
        }
        .padding(.vertical, 6)
    }
    
    private var iconColor: Color {
        if isConnected { return .green }
        if isConnecting { return .orange }
        return Color.arisePrimaryFallback
    }
    
}

