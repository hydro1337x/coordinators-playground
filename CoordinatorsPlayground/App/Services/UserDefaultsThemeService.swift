//
//  UserDefaultsThemeService.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 17.06.2025..
//

import Foundation

actor UserDefaultsThemeService: SetThemeService, GetThemeService, ThemeValuesService {
    private let defaults = UserDefaults.standard
    private let key = "app-theme"
    
    private var continuation: AsyncStream<Theme>.Continuation?
    
    var values: AsyncStream<Theme> {
        AsyncStream { continuation in
            self.continuation = continuation
            
            continuation.onTermination = { _ in
                Task { await self.clearContinuation() }
            }
        }
    }
    
    func set(theme: Theme) async {
        defaults.set(theme.rawValue, forKey: key)
        continuation?.yield(theme)
    }
    
    func getTheme() async -> Theme? {
        guard let value = defaults.string(forKey: key) else { return nil }
        return Theme(rawValue: value)
    }
    
    private func clearContinuation() {
        self.continuation = nil
    }
}
