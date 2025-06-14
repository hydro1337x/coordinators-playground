//
//  Dependencies.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 28.05.2025..
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class Dependencies {
    lazy var navigationObserver = NavigationObserver(scheduler: RunLoop.main.eraseToAnyScheduler())
    lazy var mainTabsCoordinatorAdapter = MainTabsCoordinatorAdapter()
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
    lazy var settingsCoordinatorFactory = DefaultSettingsCoordinatorFactory(themeService: themeService, mainTabsCoordinatorAdapter: mainTabsCoordinatorAdapter)
    lazy var homeCoordinatorFactory = DefaultHomeCoordinatorFactory(mainTabsCoordinatorAdapter: mainTabsCoordinatorAdapter)
    lazy var mainTabsCoordinatorFactory = DefaultMainTabsCoordinatorFactory(
        authStateService: authStateService,
        homeCoordinatorFactory: homeCoordinatorFactory,
        settingsCoordinatorFactory: settingsCoordinatorFactory,
        routerAdapter: rootRouterAdapter,
        mainTabsCoordinatorAdapter: mainTabsCoordinatorAdapter,
        navigationObserver: navigationObserver
    )
    lazy var rootCoordinatorFactory = DefaultRootCoordinatorFactory(
        authStateService: authStateService,
        authService: authService,
        accountCoordinatorFactory: accountCoordinatorFactory,
        mainTabsCoordinatorFactory: mainTabsCoordinatorFactory,
        themeService: themeService,
        routerAdapter: rootRouterAdapter,
        floatingStackStore: floatingStackStore,
        mainTabsCoordinatorAdapter: mainTabsCoordinatorAdapter,
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
