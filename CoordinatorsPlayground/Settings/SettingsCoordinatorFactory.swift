//
//  SettingsCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 14.06.2025..
//

import Foundation

@MainActor
protocol SettingsCoordinatorFactory {
    func makeRootScreen() -> Feature
}

struct DefaultSettingsCoordinatorFactory: SettingsCoordinatorFactory {
    let themeService: UserDefaultsThemeService
    let tabsCoordinatorAdapter: TabsCoordinatorAdapter
    
    func makeRootScreen() -> Feature {
        let store = SettingsRootStore(activeTabs: tabsCoordinatorAdapter.activeTabs, themeService: themeService)
        tabsCoordinatorAdapter.subscribe(to: store.$activeTabs)
        let view = SettingsRootScreen(store: store)
        return Feature(view: view, store: store)
    }
}
