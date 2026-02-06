//
//  ClipboardItem.swift
//  Pastor
//
//  Created by Victor Dombrovskiy on 14.10.2025.
//

import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let timestamp: Date
    var isFavorite: Bool
    var accessCount: Int
    var sourceApp: String?
    
    init(
        id: UUID = UUID(),
        content: String,
        timestamp: Date = Date(),
        isFavorite: Bool = false,
        accessCount: Int = 0,
        sourceApp: String? = nil
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.accessCount = accessCount
        self.sourceApp = sourceApp
    }
    
    // Equatable based on content for deduplication
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.content == rhs.content
    }
}
