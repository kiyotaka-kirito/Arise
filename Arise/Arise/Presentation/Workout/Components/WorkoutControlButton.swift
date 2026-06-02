//
//  WorkoutControlButton.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import SwiftUI

// MARK: - Button Style
enum WorkoutButtonStyle {
    case start
    case pause
    case resume
    case stop
    
    var label: String {
        switch self {
        case .start:  return "Start"
        case .pause:  return "Pause"
        case .resume: return "Resume"
        case .stop:   return "Finish"
        }
    }

    var icon: String {
        switch self {
        case .start:  return "play.fill"
        case .pause:  return "pause.fill"
        case .resume: return "play.fill"
        case .stop:   return "stop.fill"
        }
    }

    var color: Color {
        switch self {
        case .start:  return Color.arisePrimaryFallback
        case .pause:  return .orange
        case .resume: return .green
        case .stop:   return .red
        }
    }
}

// MARK: - WorkoutControlButton
struct WorkoutControlButton: View {
    
    let style: WorkoutButtonStyle
    let action: () -> Void
    
    @State private var pressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: style.icon)
                    .font(.system(size: 18, weight: .bold))
                Text(style.label)
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [style.color, style.color.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: style.color.opacity(0.4),
                        radius: pressed ? 4 : 12,
                        x: 0,
                        y: pressed ? 2 : 6
                    )
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeIn(duration: 0.1)) { pressed = true }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        pressed = false
                    }
                }
        )
    }
}

#Preview {
    VStack {
        WorkoutControlButton(style: .start, action: { })
        WorkoutControlButton(style: .pause, action: { })
        WorkoutControlButton(style: .resume, action: { })
        WorkoutControlButton(style: .stop, action: { })
    }
}
