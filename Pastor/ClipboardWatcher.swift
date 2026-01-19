//
//  ClipboardWatcher.swift
//  Pastor
//
//  Created by Victor Dombrovskiy on 14.10.2025.
//

import AppKit
import Combine
import SwiftUI
import CryptoKit

final class ClipboardWatcher: ObservableObject {
#if DEBUG
    lazy var storage = SecureStorage(fileName: "clipboardfileDebug", keychainKey: "com.pastor.encryptionKeyDebug")
#else
    lazy var storage = SecureStorage(fileName: "clipboardfile", keychainKey: "com.pastor.encryptionKey")
#endif
    @Published var items: [String] = [] {
        didSet {
            saveData()
        }
    }
    @Published  var isRunning: Bool = false
    private var maxItems: Int {
        let count = UserDefaults.standard.integer(forKey: SettingsView.Constants.maxItems)
        return count > 0 ? count : SettingsView.Constants.minMaxItemsRange.lowerBound
    }
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?
    
    init() {
        loadData()
        startMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkForChanges()
        }
        isRunning = true
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        isRunning = false
    }
    
    func checkForChanges() {
        let pb = NSPasteboard.general
        if pb.changeCount != lastChangeCount {
            lastChangeCount = pb.changeCount
            if let newText = pb.string(forType: .string) {
                addNewItem(newText)
            }
        }
    }
    
    func addNewItem(_ text: String) {
        if items.contains(text) {
            // existing - move to the top
            items.removeAll { $0 == text }
            items.insert(text, at: 0)
        } else {
            // new - insert and trim array
            items.insert(text, at: 0)
            if items.count > maxItems {
                items = Array(items.prefix(maxItems))
            }
        }
        saveData()
    }
    
    func removeItem(_ text: String) {
        if items.contains(text) {
            items.removeAll { $0 == text }
        }
        saveData()
    }
    
    func clearItems() {
        items.removeAll()
        saveData()
    }
    
    // MARK: - Persistence
    
    private func saveData() {
#if DEBUG
        return // skip for debug mode
#endif
        do {
            try storage.saveStrings(items)
        } catch {
            print("Error:", error)
        }
    }
    
    private func loadData() {
#if DEBUG
        for _ in 0..<1500 {
            items.append("Test \(UUID().uuidString.prefix(8))")
        }
        return // skip for debug mode
#endif
        do {
            items = try storage.loadStrings()
        } catch {
            print("Error:", error)
        }
    }
    
}

