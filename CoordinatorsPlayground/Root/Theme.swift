//
//  Theme.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 26.05.2025..
//

import Foundation

// This can be a Domain object
enum Theme: String {
    case light, dark
}

import SwiftUI

// In UI layer we can implement the extension for Colors
extension Theme {
    var background: Color {
        switch self {
        case .light:
            .white
        case .dark:
            .black
        }
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .light
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
