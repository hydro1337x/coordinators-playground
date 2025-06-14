//
//  Dependencies.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 28.05.2025..
//

import Foundation
import SwiftUI

final class RootRouterAdapter {
    var onUnhandledRoute: (Route) async -> Bool = unimplemented(return: false)
}

final class TabsCoordinatorAdapter {
    let activeTabs: [Tab] = [.home, .search, .settings]
    var onScreenAPushed: () -> Void = unimplemented()
    var onScreenAPopped: () -> Void = unimplemented()
    var onTabsChanged: ([Tab]) -> Void = unimplemented()
    
    func handlePop(path: [HomeCoordinatorStore.Path]) {
        if path.contains(.screenA) {
            onScreenAPopped()
        }
    }
}

import Combine

@MainActor
final class Dependencies {
    lazy var navigationObserver = NavigationObserver(scheduler: RunLoop.main.eraseToAnyScheduler())
    lazy var tabsCoordinatorAdapter = TabsCoordinatorAdapter()
    lazy var rootRouterAdapter = RootRouterAdapter()
    lazy var themeService = UserDefaultsThemeService()
    lazy var themeStore = ThemeStore(themeService: themeService)
    lazy var snapshotService = UserDefaultsRestorableSnapshotService()
    lazy var authStateService = AuthStateProvider()
    lazy var authService = AuthService(service: authStateService)
    lazy var floatingStackStore = FloatingStackStore(
        clock: ContinuousClock(),
        topVisibleState: navigationObserver.$topVisibleState.eraseToAnyPublisher()
    )
    lazy var accountCoordinatorFactory = DefaultAccountCoordinatorFactory(authService: authService)
    lazy var settingsCoordinatorFactory = DefaultSettingsCoordinatorFactory(themeService: themeService, tabsCoordinatorAdapter: tabsCoordinatorAdapter)
    lazy var homeCoordinatorFactory = DefaultHomeCoordinatorFactory(tabsCoordinatorAdapter: tabsCoordinatorAdapter)
    lazy var tabsCoordinatorFactory = DefaultTabsCoordinatorFactory(
        authStateService: authStateService,
        homeCoordinatorFactory: homeCoordinatorFactory,
        settingsCoordinatorFactory: settingsCoordinatorFactory,
        routerAdapter: rootRouterAdapter,
        tabsCoordinatorAdapter: tabsCoordinatorAdapter,
        navigationObserver: navigationObserver
    )
    lazy var rootCoordinatorFactory = DefaultRootCoordinatorFactory(
        authStateService: authStateService,
        authService: authService,
        accountCoordinatorFactory: accountCoordinatorFactory,
        tabsCoordinatorFactory: tabsCoordinatorFactory,
        themeService: themeService,
        routerAdapter: rootRouterAdapter,
        floatingStackStore: floatingStackStore,
        tabsCoordinatesAdapter: tabsCoordinatorAdapter,
        navigationObserver: navigationObserver
    )
    
    func makeRootCoordinator() -> Feature {
        let router = RootRouter<RootStep>()
        let restorer = DefaultRestorer<RootState>()
        rootRouterAdapter.onUnhandledRoute = { route in
            return await router.onUnhandledRoute(route)
        }
        let store = RootCoordinatorStore(
            flow: .tabs,
            authStateService: authStateService,
            authService: authService,
            factory: rootCoordinatorFactory,
            router: LoggingRouterDecorator(decorating: router),
            restorer: LoggingRestorerDecorator(wrapping: restorer)
        )
        navigationObserver.register(root: store)
        navigationObserver.observe(observable: store, flow: \.$flow, destination: \.$destination)
        let view = RootCoordinator(
            store: store
        )
        return Feature(view: view, store: store)
    }
    
    func makeAppStore() -> AppStore {
        let store = AppStore(
            makeRootFeature: makeRootCoordinator,
            themeStore: themeStore,
            snapshotService: snapshotService
        )
        return store
    }
}
