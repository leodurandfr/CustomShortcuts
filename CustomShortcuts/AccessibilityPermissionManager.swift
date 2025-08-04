//AccessibilityPermissionManager.swift
import Foundation
import AppKit

class AccessibilityPermissionManager: ObservableObject {
    static let shared = AccessibilityPermissionManager()
    
    @Published var isAccessibilityEnabled = false
    private var permissionRequestTimer: Timer?
    private var permissionRequested = false
    
    private init() {
        isAccessibilityEnabled = AXIsProcessTrusted()
    }
    
    func checkInitialPermissions() {
        print("Vérification initiale des permissions d'accessibilité...")
        isAccessibilityEnabled = AXIsProcessTrusted()
        
        if !isAccessibilityEnabled {
            requestPermissions()
        }
    }
    
    func requestPermissions() {
        guard !permissionRequested else { return }
        
        print("Demande des permissions d'accessibilité...")
        permissionRequested = true
        
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
            
            self.startPermissionCheckTimer()
        }
    }
    
    private func startPermissionCheckTimer() {
        permissionRequestTimer?.invalidate()
        
        permissionRequestTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            let currentTrusted = AXIsProcessTrusted()
            if currentTrusted != self.isAccessibilityEnabled {
                self.isAccessibilityEnabled = currentTrusted
                
                if currentTrusted {
                    print("Permissions d'accessibilité accordées")
                    self.permissionRequested = false
                    timer.invalidate()
                    self.permissionRequestTimer = nil
                    
                    NotificationCenter.default.post(
                        name: .accessibilityStatusDidChange,
                        object: nil
                    )
                }
            }
        }
    }
}

extension Notification.Name {
    static let accessibilityStatusDidChange = Notification.Name("AccessibilityStatusDidChange")
}
