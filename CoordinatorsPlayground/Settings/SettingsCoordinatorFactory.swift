//
//  SettingsCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 14.06.2025..
//

import Foundation

@MainActor
protocol SettingsCoordinatorFactory {
    func makeRootFeature() -> Feature
}

struct DefaultSettingsCoordinatorFactory: SettingsCoordinatorFactory {
    let themeService: UserDefaultsThemeService
    let mainTabsCoordinatorAdapter: MainTabsCoordinatorAdapter
    let rootCoordinatorAdapter: RootCoordinatorAdapter
    
    
    func makeRootFeature() -> Feature {
        let store = SettingsRootStore(activeTabs: mainTabsCoordinatorAdapter.activeTabs, themeService: themeService)
        mainTabsCoordinatorAdapter.subscribe(to: store.$activeTabs)
        rootCoordinatorAdapter.subscribe(to: store.$isNetworkReachable)
        let view = SettingsRootScreen(store: store)
        return Feature(view: view, store: store)
    }
}
