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
    
    var body: some Scene {
        MenuBarExtra("My Utility", image: "MenuBarIcon") {
            ContentView()
                .environmentObject(watcher)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
        }
    }
}

