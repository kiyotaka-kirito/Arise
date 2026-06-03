//
//  AriseTextField.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 03/06/2026.
//

import SwiftUI

// MARK: - AriseTextField
struct AriseTextField: View {
    
    // MARK: - Configuration
    let icon: String
    let placeholder: String
    @Binding var text: String
    var validation: ValidationState = .idle
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    // MARK: - State
    @State private var isFocused: Bool = false
    @State private var showPassword: Bool = false
    
    // MARK: - Computed
    private var borderColor: Color {
        switch validation {
        case .idle:         return isFocused
                            ? Color.arisePrimaryFallback
                            : Color.secondary.opacity(0.3)
        case .valid:        return .green
        case .invalid:      return .red
        }
    }
    
    private var validationMessage: String? {
        if case .invalid(let message) = validation { return message }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            // Input row
            HStack(spacing: 12) {
                
                // Leading icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(borderColor)
                    .frame(width: 20)
                    .scaleEffect(isFocused ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isFocused)
                
                // Text inout
                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(
                                keyboardType == .emailAddress ? .never : .words
                            )
                    }
                }
                .font(.subheadline)
                .onTapGesture { isFocused = true }
                
                // Trailing: show /hide password OR validation icon
                if isSecure {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash": "eye")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    validationIcon
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.secondary.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor, lineWidth: isFocused ? 1.5 : 1)
                    )
            )
            .modifier(ShakeEffect(trigger: validation == .invalid("")))
            
            // Error message (slides in from top)
            if let message = validationMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                    Text(message)
                        .font(.caption)
                }
                .foregroundStyle(.red)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    )
                )
            }
        }
        .onChange(of: text) { _, _ in
            if !isFocused { isFocused = true }
        }
    }
    
    // MARK: - Validation Icon
    @ViewBuilder
    private var validationIcon: some View {
        switch validation {
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 16))
                .transition(.scale.combined(with: .opacity))
            
        case .invalid:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.system(size: 16))
                .transition(.scale.combined(with: .opacity))
            
        case .idle:
            EmptyView()
        }
    }
    
}


// MARK: - ShakeEffect
struct ShakeEffect: ViewModifier {
    let trigger: Bool
    @State private var shaking = false
    
    func body(content: Content) -> some View {
        content
            .offset(x: shaking ? -6 : 0)
            .onChange(of: trigger) { _, newValue in
                guard newValue else { return }
                withAnimation(.easeInOut(duration: 0.05).repeatCount(4, autoreverses: true)) {
                    shaking = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shaking = false
                }
            }
    }
}
