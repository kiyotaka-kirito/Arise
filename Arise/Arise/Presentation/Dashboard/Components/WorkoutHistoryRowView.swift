//
//  WorkoutHistoryRowView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import SwiftUI

// MARK: - WorkoutHistoryRowView
struct WorkoutHistoryRowView: View {
    
    let session: WorkoutSession
    
    // Relative time formatter - shows "2 hours ago", "Yesterday", etc.
    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: session.startTime, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 14) {
            
            // Workout type icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: session.type.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconBackgroundColor)
            }
            
            // Workout details
            VStack(alignment: .leading, spacing: 4) {
                Text(session.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(relativeTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Stats on the right
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.formattedDistance)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(session.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Different color - workout type
    private var iconBackgroundColor: Color {
        switch session.type {
        case .running:          return .orange
        case .cycling:          return .blue
        case .swimming:         return .cyan
        case .weightLifting:    return .purple
        case .yoga:             return .green
        case .hiit:             return .red
        case .walking:          return .teal
        case .hiking:           return .brown
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        WorkoutHistoryRowView(session: WorkoutSession(userId: "1", type: .running))
        WorkoutHistoryRowView(session: WorkoutSession(userId: "2", type: .cycling))
        WorkoutHistoryRowView(session: WorkoutSession(userId: "3", type: .swimming))
        WorkoutHistoryRowView(session: WorkoutSession(userId: "4", type: .weightLifting))
        WorkoutHistoryRowView(session: WorkoutSession(userId: "5", type: .yoga))
        WorkoutHistoryRowView(session: WorkoutSession(userId: "6", type: .hiit))
        WorkoutHistoryRowView(session: WorkoutSession(userId: "7", type: .walking))
        WorkoutHistoryRowView(session: WorkoutSession(userId: "8", type: .hiking))
    }
    
}
