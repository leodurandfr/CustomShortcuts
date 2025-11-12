# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CustomShortcuts is a native macOS app built with SwiftUI that allows users to create and manage custom keyboard shortcuts. Users can remap existing shortcuts to new ones, either system-wide or for specific applications. For example, transform `Ctrl+C` into `Cmd+C` in a specific application.

**Tech Stack:**
- SwiftUI for UI
- AppKit/Cocoa for macOS integration
- Core Graphics (CGEvent API) for keyboard event interception
- [HotKey library](https://github.com/soffes/HotKey) (Swift Package Manager)
- Accessibility API for keyboard monitoring

**Requirements:**
- macOS 11.0 (Big Sur) or later
- Accessibility permissions (required for keyboard event interception)

## Building and Running

### Build the app
```bash
# Open in Xcode
open CustomShortcuts.xcodeproj

# Or build from command line
xcodebuild -project CustomShortcuts.xcodeproj -scheme CustomShortcuts -configuration Debug build
```

### Run tests
```bash
# Unit tests
xcodebuild test -project CustomShortcuts.xcodeproj -scheme CustomShortcuts -destination 'platform=macOS'

# UI tests
xcodebuild test -project CustomShortcuts.xcodeproj -scheme CustomShortcutsUITests -destination 'platform=macOS'
```

### Important Build Settings
- Team ID: `7C2S8B9978` (set in project.pbxproj)
- Bundle ID: `leodurand.CustomShortcuts`
- Deployment target: macOS 15.1 (but README states macOS 11.0+)
- App Sandbox: Enabled
- Hardened Runtime: Enabled

## Architecture

### Core Components

**ShortcutManager** (`ShortcutManager.swift`) - The central singleton managing all shortcut mappings
- Handles keyboard event interception via CGEvent tap
- Manages activation/deactivation of shortcut mappings
- Persists mappings using `ShortcutStorage`
- Monitors accessibility permissions
- Import/export functionality

**ApplicationsViewModel** (`ApplicationsViewModel.swift`) - Manages the list of applications
- Loads/saves applications using `StorageManager`
- Handles icon caching
- Manages selected context (system vs specific app)

**ShortcutActivationService** (`ShortcutActivationService.swift`) - Handles activation lifecycle
- Bridges UI toggle actions to ShortcutManager
- Manages pending mappings when accessibility permissions aren't granted
- Error handling for activation failures

### Data Models

**ShortcutMapping** (`ShortcutMapping.swift`)
- Represents a single shortcut remapping
- Contains source/target HotkeyData, enabled state, and context (system or app bundle ID)

**HotkeyData** (`HoykeyData.swift`) - Note: filename has typo
- Encapsulates keyboard shortcut data (keyCode, modifiers, character)
- Provides matching logic for NSEvent comparison
- Display formatting with modifier symbols (⌃⌥⇧⌘)

**CustomApplication** (`CustomApplication.swift`)
- Represents an application with shortcuts
- Stores name, bundleIdentifier, and URL

### Storage

**ShortcutStorage** (`ShortcutStorage.swift`)
- Persists `ShortcutMapping` instances to UserDefaults
- JSON encoding/decoding

**StorageManager** (`StorageManager.swift`)
- Persists `CustomApplication` instances to UserDefaults
- Separate from ShortcutStorage despite similar purpose

### Event Flow

1. User toggles a shortcut → `ShortcutActivationService.activateMapping()`
2. Service checks accessibility permissions
3. Calls `ShortcutManager.enableShortcutMapping()`
4. Creates CGEvent tap with callback pointing to `handleEvent()`
5. When matching keyboard event occurs:
   - `handleEvent()` checks context (app-specific first, then system)
   - Matches source hotkey against NSEvent
   - Calls `simulateKeyPress()` with target hotkey
   - Returns nil to suppress original event

### UI Structure

**CustomShortcutsApp** (`CustomShortcutsApp.swift`)
- Main app entry point
- Sets up menu bar (About, Import/Export, Add Application)
- AppDelegate handles window lifecycle and status bar

**ContentView** (`ContentView.swift`)
- Main container view (not yet examined in detail)

**SidebarView** (`SidebarView.swift`)
- Navigation between "All system" and app-specific shortcuts

**HotkeyRecorderField** (`HotkeyRecorderField.swift`)
- Custom control for recording keyboard shortcuts

**HotkeyMappingRow** (`HotkeyMappingRow.swift`)
- Individual row displaying a shortcut mapping

### Accessibility Permissions

The app requires Accessibility permissions to intercept keyboard events. Permission handling:
- `ShortcutManager.requestAccessibilityPermissions()` prompts user
- `AccessibilityPermissionManager` monitors permission state (referenced but not yet examined)
- Polling timer checks `AXIsProcessTrusted()` every 1 second
- Notifications posted on permission changes

### Import/Export

JSON-based configuration sharing:
- `ShortcutManager.exportShortcuts(to:)` encodes all mappings
- `ShortcutManager.importShortcuts(from:)` decodes and merges
- Import automatically adds applications if not already in list
- Default location: Downloads folder

## Localization

- Supports French and English (see Info.plist)
- Uses `NSLocalizedString` for user-facing text

## Key Dependencies

- **HotKey**: External Swift package for keyboard shortcut utilities (from soffes/HotKey)

## Development Notes

### Typos in Codebase
- `HoykeyData.swift` should be `HotkeyData.swift` (filename typo)

### Separation of Concerns
- Two separate storage managers (`ShortcutStorage` and `StorageManager`) handle different data types
- Consider consolidation if refactoring

### Permission Handling
- Permission requests use polling rather than reactive observation
- Timer invalidates once permissions granted

### Event Tap Implementation
- Single global event tap per enabled mapping approach
- App-specific shortcuts checked before system shortcuts in `handleEvent()`
- Unmanaged pointer pattern used to pass ShortcutManager instance to C callback
