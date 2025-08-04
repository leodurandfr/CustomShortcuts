import SwiftUI

struct NameField: View {
    @Binding var text: String
    let placeholder: String
    let isDisabled: Bool
    let isAlternate: Bool
    @State private var isHovered = false
    
    init(text: Binding<String>, placeholder: String, isDisabled: Bool, isAlternate: Bool = false) {
        self._text = text
        self.placeholder = placeholder
        self.isDisabled = isDisabled
        self.isAlternate = isAlternate
    }
    
    private func getTextColor() -> Color {
        if text.isEmpty {
            return Color.gray
        } else {
            return CustomColors.fieldText(isDisabled: isDisabled)
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            if isDisabled {
                Text(text.isEmpty ? placeholder : text)
                    .foregroundColor(text.isEmpty ? Color.gray : getTextColor())
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .foregroundColor(getTextColor())
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: 28)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(CustomColors.fieldBackground(isDisabled: isDisabled, isAlternate: isAlternate))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    CustomColors.fieldBorder(isDisabled: isDisabled, isAlternate: isAlternate),
                    lineWidth: 1
                )
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
