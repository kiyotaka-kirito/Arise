//
//  HeartRateMonitorView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 04/06/2026.
//

import SwiftUI

struct HeartRateMonitorView: View {
    
    let bpm: Double
    let zone: HeartRateZone
    let deviceName: String
    let batteryLevel: Int
    
    // Heartbeat animation state
    @State private var heartScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0
    @State private var lastBPM: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            
            // Devices status bar
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                
                Text(deviceName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Battery indicator
                if batteryLevel >= 0 {
                    HStack(spacing: 4) {
                        Image(systemName: batteryIcon)
                            .font(.caption)
                            .foregroundStyle(batteryColor)
                        Text("\(batteryLevel)%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Heart rate display
            HStack(spacing: 20) {
                
                // Animated heart icon
                ZStack {
                    Circle()
                        .stroke(zoneSwiftUIColor.opacity(ringOpacity), lineWidth: 3)
                        .frame(width: 64, height: 64)
                        .scaleEffect(heartScale * 1.3)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(zoneSwiftUIColor)
                        .scaleEffect(heartScale)
                }
                .frame(width: 64, height: 64)
                
                VStack(alignment: .leading, spacing: 2) {
                    // BPM value
                    Text(bpm > 0 ? "\(Int(bpm))" : "--")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    
                    HStack(spacing: 6) {
                        Text("BPM")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if bpm > 0 {
                            Text(zone.displayName)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(zoneSwiftUIColor)
                                )
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ariseCardFallback)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        // Trigger heartbeat animation
        .onChange(of: bpm) { _, newBPM in
            guard newBPM > 0 else { return }
            triggerHeartbeat()
        }
        .animation(.spring(response: 0.3), value: bpm)
    }
    
    // MARK: - Heartbeat Animation
    private func triggerHeartbeat() {
        // Beat 1: compress
        withAnimation(.easeIn(duration: 0.1)) {
            heartScale = 0.85
            ringOpacity = 0.8
        }
        
        // Beat 2: expand
        withAnimation(.spring(response: 0.25, dampingFraction: 0.4).delay(0.1)) {
            heartScale = 1.5
        }
        
        // Beat 3: settle and ring fades
        withAnimation(.easeInOut(duration: 0.3).delay(0.25)) {
            heartScale = 1.0
            ringOpacity = 0
        }
    }
    
    // MARK: - Helpers
    private var zoneSwiftUIColor: Color {
        switch zone {
        case .rest:         return .blue
        case .fatBurn:      return .green
        case .cardio:       return .yellow
        case .peak:         return .orange
        case .maximum:      return .red
        }
    }
    
    private var batteryIcon: String {
        switch batteryLevel {
        case 75...100:      return "battery.100"
        case 50..<75:       return "battery.75"
        case 25..<50:       return "battery.25"
        default:            return "battery.0"
        }
    }
    
    private var batteryColor: Color {
        batteryLevel > 20 ? .secondary : .red
    }
    
}

