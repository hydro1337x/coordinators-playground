//
//  DefaultSettingsCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 17.06.2025..
//

import Foundation

struct DefaultSettingsCoordinatorFactory: SettingsCoordinatorFactory {
    let themeService: UserDefaultsThemeService
    let mainTabsCoordinatorAdapter: MainTabsCoordinatorAdapter
    let rootCoordinatorAdapter: RootCoordinatorAdapter
    
    
    func makeRootFeature() -> Feature {
        let store = SettingsRootStore(activeTabs: mainTabsCoordinatorAdapter.activeTabs, themeService: themeService)
        mainTabsCoordinatorAdapter.subscribe(to: store.$activeTabs)
        rootCoordinatorAdapter.subscribe(to: store.$isNetworkReachable)
        store.onShowSpecialFlowButtonTapped = {
            rootCoordinatorAdapter.onShowSpecialFlow()
        }
        let view = SettingsRootScreen(store: store)
        return Feature(view: view, store: store)
    }
}
