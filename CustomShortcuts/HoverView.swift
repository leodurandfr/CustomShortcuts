import Foundation
import SwiftUI

struct HoverView<Content: View>: View {
    let content: (Bool) -> Content
    @State private var isHovered = false
    
    init(@ViewBuilder content: @escaping (Bool) -> Content) {
        self.content = content
    }
    
    var body: some View {
        content(isHovered)
            .onHover { hover in
                isHovered = hover
            }
    }
}
