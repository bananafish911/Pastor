//
//  PastorApp.swift
//  Pastor
//
//  Created by Victor Dombrovskiy on 14.10.2025.
//

import SwiftUI

@main
struct MenuBarApp: App {
    @StateObject private var watcher = ClipboardWatcher()
    
    #if DEBUG
    private let menuBarIcon = "MenuBarIcon.debug"
    private let menuBarTitle = "My Utility (DEBUG)"
    #else
    private let menuBarIcon = "MenuBarIcon"
    private let menuBarTitle = "My Utility"
    #endif
    
    var body: some Scene {
        MenuBarExtra(menuBarTitle, image: menuBarIcon) {
            ContentView()
                .environmentObject(watcher)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
        }
    }
}

