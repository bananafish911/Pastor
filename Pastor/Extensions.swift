//
//  Extensions.swift
//  Pastor
//
//  Created by Victor Dombrovskiy on 15.10.2025.
//

import Foundation

extension String {
    
    func trimmingLeadingWhitespaceAndNewlines() -> String {
        let trimmed = drop { $0.isWhitespace || $0.isNewline }
        return String(trimmed)
    }
    
    func truncated(to length: Int, trailing: String = "...") -> String {
        guard self.count > length else { return self }
        let endIndex = index(startIndex, offsetBy: length)
        return String(self[..<endIndex]) + trailing
    }
    
}
