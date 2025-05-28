//
//  Dependencies.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 28.05.2025..
//

import Foundation

final class RootRouterAdapter {
    var onUnhandledRoute: (Route) async -> Bool = unimplemented(return: false)
}

@MainActor
final class Dependencies {
    lazy var rootRouterAdapter = RootRouterAdapter()
    lazy var themeManager = ThemeManager()
    lazy var authStateService = AuthStateProvider()
    lazy var authService = AuthService(service: authStateService)
    lazy var accountCoordinatorFactory = AccountCoordinatorFactory()
    lazy var homeCoordinatorFactory = HomeCoordinatorFactory()
    lazy var tabsCoordinatorFactory = TabsCoordinatorFactory(
        authStateService: authStateService,
        homeCoordinatorFactory: homeCoordinatorFactory,
        routerAdapter: rootRouterAdapter
    )
    lazy var rootCoordinatorFactory = RootCoordinatorFactory(
        authStateService: authStateService,
        authService: authService,
        accountCoordinatorFactory: accountCoordinatorFactory,
        tabsCoordinatorFactory: tabsCoordinatorFactory,
        themeManager: themeManager,
        routerAdapter: rootRouterAdapter
    )
    
    func makeRootCoordinatorStore() -> RootCoordinatorStore {
        let router = RootRouter<RootStep>()
        let restorer = DefaultRestorer<RootState>()
        rootRouterAdapter.onUnhandledRoute = { route in
            return await router.onUnhandledRoute(route)
        }
        let store = RootCoordinatorStore(
            authStateService: authStateService,
            authService: authService,
            factory: rootCoordinatorFactory,
            router: LoggingRouterDecorator(decorating: router),
            restorer: LoggingRestorerDecorator(wrapping: restorer)
        )
        return store
    }
}
