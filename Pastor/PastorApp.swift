//
//  PastorApp.swift
//  Pastor
//
//  Created by Victor Dombrovskiy on 14.10.2025.
//

import SwiftUI

// TODO: - utility app clipboard manager

/*
 truly air-gapped
 simple: store X items, copy by click
 */

@main
struct MenuBarApp: App {
    @StateObject private var watcher = ClipboardWatcher()
    
    var body: some Scene {
        MenuBarExtra("My Utility", image: "MenuBarIcon") {
            ContentView()
                .environmentObject(watcher)
        }
        .menuBarExtraStyle(.window)
//        .menuBarExtraStyle(.menu)
        
        Settings {
            SettingsView()
        }
    }
}

