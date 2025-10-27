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
    @State private var showClearConfirmation = false
    @State private var searchText: String = ""
    
    var filteredItems: [String] {
        if searchText.isEmpty {
            return watcher.items
        } else {
            return watcher.items.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack {
            SearchField(text: $searchText)
            VStack(alignment: .leading, spacing: 1) {
                ForEach(filteredItems, id: \.self) { item in
                    let textLimit: Int = 64
                    HoverButton(text: item.trimmingLeadingWhitespaceAndNewlines(),
                                textLimit: textLimit,
                                onDelete: {
                        watcher.removeItem(item)
                        print(item)
                    }, onTap: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(item, forType: .string)
                        searchText = ""
                        dismiss()
                    })
                    .lineLimit(1)
                    .help(item.count > textLimit ? item : "")
                }
            }
            Divider()
            if watcher.items.count > 0 {
                Button("Clear all") {
                    showClearConfirmation = true
                }
                .buttonStyle(.borderless)
                .confirmationDialog("Are you sure you want to clear all clipboard items?",
                                    isPresented: $showClearConfirmation) {
                    Button("Clear All", role: .destructive) {
                        watcher.clearItems()
                    }
                    Button("Cancel", role: .cancel) { }
                }
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
    }
}

#Preview("ContentView") {
    ContentView()
        .environmentObject(ClipboardWatcher())
        .frame(width: 300, height: 400)
}

// MARK: - Utils

struct HoverButton: View {
    let text: String
    let textLimit: Int
    let onDelete: () -> Void
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(text.trimmingCharacters(in: .whitespacesAndNewlines)
                    .prefix(textLimit))
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
        .focusable(false)// Prevents default macOS blue highlight
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
