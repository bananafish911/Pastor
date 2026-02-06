//
//  LaunchAtLoginHelper.swift
//  Pastor
//
//  Created by Victor Dombrovskiy on 14.10.2025.
//

import Foundation
import ServiceManagement

/// Helper class to manage the "Launch at Login" functionality
@MainActor
class LaunchAtLoginHelper: ObservableObject {
    @Published var isEnabled: Bool = false
    
    init() {
        // Check current status
        updateStatus()
    }
    
    /// Updates the published status based on current system state
    func updateStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    /// Toggles the launch at login setting based on desired state
    func setEnabled(_ enabled: Bool) async throws {
        if enabled {
            try await enable()
        } else {
            try await disable()
        }
    }
    
    /// Enables launch at login
    func enable() async throws {
        if SMAppService.mainApp.status == .enabled {
            isEnabled = true
            return
        }
        
        do {
            try SMAppService.mainApp.register()
            isEnabled = true
        } catch {
            isEnabled = false
            throw LaunchAtLoginError.failedToEnable(error)
        }
    }
    
    /// Disables launch at login
    func disable() async throws {
        do {
            try await SMAppService.mainApp.unregister()
            isEnabled = false
        } catch {
            throw LaunchAtLoginError.failedToDisable(error)
        }
    }
}

enum LaunchAtLoginError: LocalizedError {
    case failedToEnable(Error)
    case failedToDisable(Error)
    
    var errorDescription: String? {
        switch self {
        case .failedToEnable(let error):
            return "Failed to enable launch at login: \(error.localizedDescription)"
        case .failedToDisable(let error):
            return "Failed to disable launch at login: \(error.localizedDescription)"
        }
    }
}
