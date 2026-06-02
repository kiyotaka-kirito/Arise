//
//  WorkoutTypePickerView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import SwiftUI

struct WorkoutTypePickerView: View {
    
    @Binding var selectedType: WorkoutType
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Activity")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(WorkoutType.allCases, id: \.self) { type in
                    WorkoutTypeCell(
                        type: type,
                        isSelected: selectedType == type,
                        onTap: { selectedType = type }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
}

#Preview {
    WorkoutTypePickerView(selectedType: .constant(.cycling))
}

// MARK: - WorkoutTypeCell
private struct WorkoutTypeCell: View {
    
    let type: WorkoutType
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var pressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            isSelected
                            ? Color.arisePrimaryFallback
                            : Color.ariseCardFallback
                        )
                        .shadow(
                            color: isSelected
                            ? Color.arisePrimaryFallback.opacity(0.4)
                            : .black.opacity(0.06),
                            radius: isSelected ? 12 : 6,
                            x: 0, y: 4
                        )
                    
                    Image(systemName: type.iconName)
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(isSelected ? .white : .primary)
                }
                .frame(height: 64)
                .scaleEffect(pressed ? 0.94 : 1.0)
                
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(
                        isSelected ? Color.arisePrimaryFallback : .secondary
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeIn(duration: 0.1)) { pressed = true }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        pressed = false
                    }
                }
        )
        
    }
    
}
