//
//  ThemeStore.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 26.05.2025..
//

import Foundation

@MainActor
class ThemeStore: ObservableObject {
    @Published var currentTheme: Theme = .light
    
    private let themeService: SetThemeService & GetThemeService & ThemeValuesService
    
    init(themeService: SetThemeService & GetThemeService & ThemeValuesService) {
        self.themeService = themeService
    }
    
    func handleOnFirstAppear() {
        Task {
            if let theme = await themeService.getTheme() {
                self.currentTheme = theme
            }
            
            for await theme in await themeService.values {
                self.currentTheme = theme
            }
        }
    }
    
    func set(theme: Theme) {
        Task {
            await themeService.set(theme: theme)
            currentTheme = theme
        }
    }
}
