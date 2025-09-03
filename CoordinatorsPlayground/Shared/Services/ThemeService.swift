//
//  ThemeService.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 17.06.2025..
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
