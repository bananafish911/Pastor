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
        static let minMaxItemsRange: ClosedRange<Int> = 20...3000
    }
    
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var launchAtLoginHelper = LaunchAtLoginHelper()
    @AppStorage(Constants.maxItems) private var maxItems = Constants.minMaxItemsRange.lowerBound
    @State private var showError = false
    @State private var errorMessage = ""
    
    
    var body: some View {
        VStack {
            Toggle("Launch at login", isOn: $launchAtLoginHelper.isEnabled)
                .onChange(of: launchAtLoginHelper.isEnabled) { oldValue, newValue in
                    Task {
                        do {
                            try await launchAtLoginHelper.setEnabled(newValue)
                        } catch {
                            // Revert on error
                            launchAtLoginHelper.isEnabled = oldValue
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            Stepper("Remember items \(maxItems)", onIncrement: {
                let newValue = maxItems + 10
                if Constants.minMaxItemsRange.contains(newValue) {
                    maxItems = newValue
                } else {
                    maxItems = Constants.minMaxItemsRange.upperBound
                }
            }, onDecrement: {
                let newValue = maxItems - 10
                if Constants.minMaxItemsRange.contains(newValue) {
                    maxItems = newValue
                } else {
                    maxItems = Constants.minMaxItemsRange.lowerBound
                }
            })
            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding(20)
        .frame(width: 200, height: 200)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    SettingsView()
}
