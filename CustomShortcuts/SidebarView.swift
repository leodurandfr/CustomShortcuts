import SwiftUI
import ServiceManagement


struct SidebarView: View {
    @ObservedObject var appsViewModel: ApplicationsViewModel
    @State private var launchAtStartup = UserDefaults.standard.bool(forKey: "launchAtStartup")
    
    var body: some View {
        VStack {
            List(selection: Binding(
                get: { appsViewModel.selectedContext },
                set: { newValue in
                    DispatchQueue.main.async {
                        appsViewModel.selectedContext = newValue
                    }
                }
            )) {
                systemSection
                applicationsSection
            }
            .listStyle(SidebarListStyle())
            
            HStack {
                Text(NSLocalizedString("Launch at startup", comment: ""))
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { launchAtStartup },
                    set: { newValue in
                        launchAtStartup = newValue
                        UserDefaults.standard.set(newValue, forKey: "launchAtStartup")
                        
                        if newValue {
                            try? SMAppService.mainApp.register()
                        } else {
                            try? SMAppService.mainApp.unregister()
                        }
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: Color.gray))
                .controlSize(.mini)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private var systemSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "square.grid.2x2")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tertiary)
                .font(.system(size: 16))
            Text(NSLocalizedString("All system", comment: ""))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tag("system")
        .foregroundColor(.primary)
    }
    
    private var applicationsSection: some View {
        Group {
            sectionHeader
            ForEach(appsViewModel.applications) { app in
                applicationRow(app)
            }
        }
    }
    
    private var sectionHeader: some View {
        HStack {
            Text("Applications")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
            //.frame(height: 24)
            Spacer(minLength: 0)
            CircleIconButton(
                systemName: "plus.circle",
                action: {
                    appsViewModel.addApplication()
                },
                helpText: "Ajouter une application"
            )
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
        //.background(.red)
    }
    
    private func applicationRow(_ app: CustomApplication) -> some View {
        HoverView { isHovered in
            HStack(spacing: 4) {
                if let icon = appsViewModel.getIcon(for: app) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                } else {
                    // Montrer un placeholder pendant le chargement de l'icône
                    Image(systemName: "app")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                Text(app.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                if isHovered {
                    CircleIconButton(
                        systemName: "minus.circle",
                        action: {
                            DispatchQueue.main.async {
                                appsViewModel.removeApplication(app)
                            }
                        },
                        helpText: "Supprimer l'application"
                    )
                }
            }
        }
        .tag(app.bundleIdentifier)
    }
}
