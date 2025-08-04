// HotkeyMappingRow.swift
import SwiftUI

struct HotkeyMappingRow: View {
    @Binding var mapping: ShortcutMapping
    @State private var isRecordingSource = false
    @State private var isRecordingTarget = false
    let shortcutManager: ShortcutManager
    let onDelete: () -> Void
    let isAlternate: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            NameField(
                text: Binding(
                    get: { mapping.name ?? "" },
                    set: { mapping.name = $0 }
                ),
                placeholder: "Nom",
                isDisabled: mapping.isEnabled,
                isAlternate: isAlternate 
            )
            .frame(minWidth: 140, idealWidth: 140)

            // Premier champ - raccourci à remplacer (source)
            HotkeyRecorderField(
                hotkeyData: $mapping.targetHotkey,
                isRecording: $isRecordingTarget,
                isDisabled: mapping.isEnabled,
                isAlternate: isAlternate // Transmettre l'info isAlternate
            )
            .frame(minWidth: 140, idealWidth: 140)

            Image(systemName: "arrow.right")
                .frame(width: 4)
                .font(.system(size: 12))
                .foregroundColor(Color.secondary)

            // Second champ - nouveau raccourci (cible)
            HotkeyRecorderField(
                hotkeyData: $mapping.sourceHotkey,
                isRecording: $isRecordingSource,
                isDisabled: mapping.isEnabled,
                isAlternate: isAlternate // Transmettre l'info isAlternate
            )
            .frame(minWidth: 140, idealWidth: 140)
            
            Toggle("", isOn: $mapping.isEnabled)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle())
                .controlSize(.small)
                .padding(.leading, 8)
                .onChange(of: mapping.isEnabled) { oldValue, newValue in
                    print("Toggle changed from \(oldValue) to \(newValue)")

                    guard let source = mapping.sourceHotkey,
                          let target = mapping.targetHotkey else {
                        mapping.isEnabled = false
                        return
                    }
                    
                    if newValue {
                        do {
                            print("Enabling shortcut mapping:")
                            print("- ID: \(mapping.id)")
                            print("- From: \(source)")
                            print("- To: \(target)")
                            
                            try shortcutManager.enableShortcutMapping(
                                id: mapping.id,
                                from: source,
                                to: target
                            )
                        } catch {
                            print("Error enabling shortcut: \(error)")
                            mapping.isEnabled = false
                        }
                    } else {
                        shortcutManager.disableShortcutMapping(id: mapping.id)
                    }
                }
            TrashButton(action: onDelete, isAlternate: isAlternate)
        }
        .padding(12)
        .frame(minHeight: 48)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isAlternate ? CustomColors.backgroundWindow : CustomColors.backgroundNormalRow)
        )
    }
}
