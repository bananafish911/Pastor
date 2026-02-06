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
    @Published var items: [ClipboardItem] = [] {
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
        // Check if content already exists
        if let existingIndex = items.firstIndex(where: { $0.content == text }) {
            // Move to top and increment access count
            var item = items[existingIndex]
            item.accessCount += 1
            items.remove(at: existingIndex)
            items.insert(item, at: 0)
        } else {
            // Create new item
            let newItem = ClipboardItem(content: text)
            items.insert(newItem, at: 0)
            if items.count > maxItems {
                items = Array(items.prefix(maxItems))
            }
        }
        saveData()
    }
    
    func removeItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
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
            try storage.saveItems(items)
        } catch {
            print("Error saving items:", error)
        }
    }
    
    private func loadData() {
#if DEBUG
        for i in 0..<3500 {
            items.append(ClipboardItem(
                content: "Test \(UUID().uuidString.prefix(8))",
                timestamp: Date().addingTimeInterval(TimeInterval(-i * 60))
            ))
        }
        return // skip for debug mode
#endif
        do {
            // Try loading new format first
            items = try storage.loadItems()
        } catch {
            // Fall back to legacy string format for migration
            do {
                let oldStrings = try storage.loadStrings()
                items = oldStrings.enumerated().map { index, content in
                    ClipboardItem(
                        content: content,
                        timestamp: Date().addingTimeInterval(TimeInterval(-index * 60))
                    )
                }
                // Save in new format
                try storage.saveItems(items)
            } catch {
                print("Error loading items:", error)
            }
        }
    }
    
}

