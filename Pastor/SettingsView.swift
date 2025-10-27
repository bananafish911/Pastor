//
//  SettingsView.swift
//  Pastor
//
//  Created by Victor Dombrovskiy on 14.10.2025.
//

import SwiftUI

struct SettingsView: View {
    
    struct Constants {
        static let maxItems = "maxItems"
        static let minMaxItemsRange: ClosedRange<Int> = 20...1000
        static let autoStart = "autoStart"
    }
    
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage(Constants.autoStart) private var autoStart = false
    @AppStorage(Constants.maxItems) private var maxItems = Constants.minMaxItemsRange.lowerBound
    
    
    var body: some View {
        VStack {
            Toggle("Launch at login", isOn: $autoStart)
                .disabled(true) // TODO: - implement 
            Stepper("Remember items \(maxItems)", value: $maxItems, in: Constants.minMaxItemsRange)
            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding(20)
        .frame(width: 200, height: 200)
    }
}

#Preview {
    SettingsView()
}
