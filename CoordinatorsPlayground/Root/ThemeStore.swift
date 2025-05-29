//
//  ThemeStore.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 26.05.2025..
//

import Foundation

protocol SetThemeService: Sendable {
    func set(theme: Theme) async
}

protocol ThemeValuesService: Sendable {
    var values: AsyncStream<Theme> { get async }
}

protocol GetThemeService: Sendable {
    func getTheme() async -> Theme?
}

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
