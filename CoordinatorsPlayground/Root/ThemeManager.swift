//
//  ThemeManager.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 26.05.2025..
//

import Foundation

protocol SetThemeService: Sendable {
    func set(theme: Theme) async
}

@MainActor
class ThemeManager: ObservableObject, SetThemeService {
    let defaults = UserDefaults.standard
    let key = "app-theme"
    @Published var currentTheme: Theme
    
    init() {
        if let value = defaults.string(forKey: key),
           let theme = Theme(rawValue: value) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .light
        }
    }
    
    func set(theme: Theme) async {
        defaults.set(currentTheme.rawValue, forKey: key)
        currentTheme = theme
    }
}
