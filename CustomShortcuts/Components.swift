//Components.swift
import Foundation
import SwiftUI


struct CircleIconButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    
    let systemName: String
    let action: () -> Void
    let helpText: String
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .symbolRenderingMode(.monochrome)
                .foregroundColor(getColor())
                .font(.system(size: 12)) // Taille spécifique pour correspondre à minus.circle
                .imageScale(.medium)
        }
        .buttonStyle(.borderless)
        .help(helpText)
        .onHover { hover in
            isHovered = hover
        }
    }
    
    private func getColor() -> Color {
        colorScheme == .dark ?
            Color.white.opacity(isHovered ? 0.8 : 0.4) :
            Color.black.opacity(isHovered ? 0.8 : 0.4)
    }
}




struct TrashButton: View {
    let action: () -> Void
    let isAlternate: Bool
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "trash")
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHovered ? (isAlternate ? Color(nsColor: .alternatingContentBackgroundColors[1]) : Color(nsColor: .windowBackgroundColor)) : .clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { hover in
            isHovered = hover
        }
    }
}


