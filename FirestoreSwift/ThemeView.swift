//
//  ThemeView.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 10/11/24.
//

// Custom TextField view wrapper with placeholder color support
import SwiftUI

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var backgroundColor: Color = Color(.systemGray6)
    var cornerRadius: CGFloat = 8
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color.gray.opacity(0.7))
                    .padding(.leading, 16)
            }
            
            // Text Field
            TextField("", text: $text)
                .padding()
                .background(backgroundColor)
                .cornerRadius(cornerRadius)
                .foregroundColor(.primary) // Adapts to light/dark mode
        }
    }
}

// Custom Button Style for consistent look across app
struct CustomButtonStyle: ButtonStyle {
    var foregroundColor: Color = .blue // Button text color
    var backgroundColor: Color = .blue // Button background color
    var font: Font = .body // Default font
    var cornerRadius: CGFloat = 8 // Rounded corner for buttons
    var padding: CGFloat = 10 // Padding around button text
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .padding(padding)
            .background(configuration.isPressed ? backgroundColor.opacity(0.7) : backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
    }
}
