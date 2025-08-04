import SwiftUI
import HotKey
import Carbon
import ServiceManagement


struct ContentView: View {
    @StateObject private var shortcutManager = ShortcutManager.shared
    @StateObject private var appsViewModel = ApplicationsViewModel()
    @State private var selectedContext: String = "system"
    
    var body: some View {
        NavigationSplitView {
            SidebarView(appsViewModel: appsViewModel)
                .frame(minWidth: 200, maxWidth: .infinity)
                .toolbar(removing: .sidebarToggle)
        } detail: {
            ShortcutListView(
                context: appsViewModel.selectedContext,
                shortcutManager: shortcutManager,
                appsViewModel: appsViewModel
            )
            .frame(minWidth: 612)
            .background(CustomColors.backgroundWindow)
        }
        .navigationSplitViewStyle(.balanced)
    }
}


struct ShortcutListView: View {
    let context: String
    @ObservedObject var shortcutManager: ShortcutManager
    let appsViewModel: ApplicationsViewModel
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                if shortcutManager.shortcutsForContext(context).isEmpty {
                    EmptyStateView(context: context)
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                headerView
                                ForEach(Array(shortcutManager.shortcutsForContext(context).enumerated()), id: \.element.id) { index, mapping in
                                    makeRow(for: mapping, index: index)
                                }
                            }
                            .padding(.bottom, 80)
                        }
                    }
                }
            }
            
            // Zone du bas avec gradient et bouton
                        ZStack(alignment: .bottom) {
                            // Gradient en arrière-plan
                            LinearGradient(gradient: Gradient(colors: [.clear, CustomColors.backgroundWindow]),
                                          startPoint: UnitPoint(x: 0.5, y: 0),
                                          endPoint: .bottom)
                                .frame(height: 80)
                            
                            // Bouton superposé au gradient
                            Button(action: {
                                shortcutManager.addMapping(for: context)
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text(NSLocalizedString("Add shortcut", comment: ""))
                                        .font(.system(size: 13))
                                }
                                .padding(.horizontal, 96)
                                .padding(.vertical, 8)
                                .background(isHovered ? CustomColors.secondaryButtonHover : CustomColors.secondaryButton)
                                .cornerRadius(6)
                                .animation(.easeInOut(duration: 0.16), value: isHovered)
                            }
                            .buttonStyle(.plain)
                            .onHover { hover in
                                isHovered = hover
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .background(.clear)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .navigationTitle(getNavigationTitle())
                    .toolbar {
                        ToolbarItem(placement: .navigation) { navigationIcon }
                    }
                }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            Text(NSLocalizedString("Name", comment: ""))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
            
            Text(NSLocalizedString("Old shortcut", comment: ""))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
            
            Text("")
                .frame(width: 0)
            
            Text(NSLocalizedString("New shortcut", comment: ""))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
                
            
            // Garde un espace fixe pour les boutons/actions
            Spacer()
                .frame(width: 80)
        }
        .foregroundColor(.secondary)
        .font(.system(size: 12))
        .padding(12)
    }
    
    
    private func makeRow(for mapping: ShortcutMapping, index: Int) -> some View {
        HotkeyMappingRow(
            mapping: Binding(
                get: { mapping },
                set: { newValue in
                    if let index = shortcutManager.mappings.firstIndex(where: { $0.id == mapping.id }) {
                        shortcutManager.mappings[index] = newValue
                    }
                }
            ),
            shortcutManager: shortcutManager,
            onDelete: {
                shortcutManager.deleteMapping(id: mapping.id)
            },
            isAlternate: index % 2 == 1
        )
    }

    
    private var navigationIcon: some View {
        HStack {
            if context == "system" {
                Image(systemName: "square.grid.2x2")
            } else if let app = appsViewModel.applications.first(where: { $0.bundleIdentifier == context }) {
                if let icon = appsViewModel.getIcon(for: app) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
            }
        }
    }
    
    private func getNavigationTitle() -> String {
        if context == "system" {
            return NSLocalizedString("All system", comment: "")
        } else if let app = appsViewModel.applications.first(where: { $0.bundleIdentifier == context }) {
            return app.name
        } else {
            return NSLocalizedString("Application", comment: "")
        }
    }
}

struct EmptyStateView: View {
    let context: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(NSLocalizedString("No shortcuts", comment: ""))
                .font(.title2)
            
            Text(context == "system" ?
                 NSLocalizedString("Add shortcuts that apply to the entire system", comment: "") :
                 NSLocalizedString("Add shortcuts specific to this application", comment: ""))
            .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//#Preview {
//    ContentView()
//}
