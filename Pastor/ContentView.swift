//
//  ContentView.swift
//  Pastor
//
//  Created by Victor Dombrovskiy on 14.10.2025.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var watcher: ClipboardWatcher
    @State private var searchText: String = ""
    @State private var filteredItems: [ClipboardItem] = []
    
    private let textLimit: Int = 64
    
    var body: some View {
        VStack {
            ScrollView(.vertical) {
                if watcher.items.count > 10 {
                    SearchField(text: $searchText)
                }
                if watcher.items.isEmpty {
                    Label("Items will appear here…", systemImage: "sparkles")
                }
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(filteredItems) { item in
                        HoverButton(
                            displayText: item.displayText,
                            fullText: item.fullText,
                            hasMore: item.isTruncated,
                            onDelete: {
                                watcher.removeItem(item.fullText)
                            },
                            onTap: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(item.fullText, forType: .string)
                                searchText = ""
                                dismiss()
                            }
                        )
                    }
                }
            }
            Divider()
            if watcher.items.count > 0 {
                Button("Clear all") {
                    watcher.clearItems()
                }
                .buttonStyle(.borderless)
            }
            Button(watcher.isRunning ? "Pause" : "Resume") {
                watcher.isRunning ? watcher.stopMonitoring() : watcher.startMonitoring()
            }
            .buttonStyle(.borderless)
            SettingsLink() {
                Label("Preferences…", systemImage: "gear")
            }
            .buttonStyle(.borderless)
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onDisappear {
            searchText = ""
        }
        .task(id: watcher.items) {
            updateFilteredItems()
        }
        .onChange(of: searchText) { _, _ in
            updateFilteredItems()
        }
    }
    
    private func updateFilteredItems() {
        let items = watcher.items
        let search = searchText.lowercased()
        
        // Perform filtering and transformation off main thread for large datasets
        if items.count > 500 {
            Task.detached(priority: .userInitiated) {
                let filtered = filterAndTransform(items: items, searchText: search)
                await MainActor.run {
                    self.filteredItems = filtered
                }
            }
        } else {
            filteredItems = filterAndTransform(items: items, searchText: search)
        }
    }
    
    private nonisolated func filterAndTransform(items: [String], searchText: String) -> [ClipboardItem] {
        let filtered = searchText.isEmpty 
            ? items 
            : items.filter { $0.localizedCaseInsensitiveContains(searchText) }
        
        return filtered.enumerated().map { index, text in
            ClipboardItem(
                index: index,
                fullText: text,
                textLimit: textLimit
            )
        }
    }
}

// MARK: - Models

struct ClipboardItem: Identifiable {
    let id: Int
    let fullText: String
    let displayText: String
    let isTruncated: Bool
    
    init(index: Int, fullText: String, textLimit: Int) {
        self.id = index
        self.fullText = fullText
        
        let trimmed = fullText.trimmingLeadingWhitespaceAndNewlines()
        self.isTruncated = trimmed.count > textLimit
        self.displayText = String(trimmed.prefix(textLimit))
    }
}

#Preview("ContentView") {
    ContentView()
        .environmentObject(ClipboardWatcher())
        .frame(width: 300, height: 400)
}

// MARK: - Utils

struct HoverButton: View {
    let displayText: String
    let fullText: String
    let hasMore: Bool
    let onDelete: () -> Void
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(displayText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if isHovered {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .onTapGesture {
                            onDelete()
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.gray.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(hasMore ? fullText : "")
        .focusable(false) // Prevents default macOS blue highlight
    }
}

struct SearchField: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSSearchField {
        let searchField = TallSearchField()
        searchField.delegate = context.coordinator
        return searchField
    }
    
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // 👇 Subclass to customize intrinsic height
    class TallSearchField: NSSearchField {
        override var intrinsicContentSize: NSSize {
            let size = super.intrinsicContentSize
            return NSSize(width: size.width, height: size.height * 1.2)
        }
    }
    
    class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: SearchField
        init(_ parent: SearchField) { self.parent = parent }
        
        func controlTextDidChange(_ obj: Notification) {
            if let field = obj.object as? NSSearchField {
                parent.text = field.stringValue
            }
        }
    }
}

