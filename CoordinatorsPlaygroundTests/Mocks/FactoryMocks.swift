//
//  FactoryMocks.swift
//  CoordinatorsPlaygroundTests
//
//  Created by Benjamin Macanovic on 07.06.2025..
//

import Foundation
import SwiftUI
@testable import CoordinatorsPlayground

struct AuthStateServiceMock: AuthTokenLoginService, LogoutService {
    let service: SetAuthStateService
    
    func login(authToken: String?) async throws {
        guard authToken != nil else { throw URLError(.badServerResponse) }
        
        await service.setState(.loginInProgress)
        await service.setState(.loggedIn)
    }
    
    func logout() async {
        await service.setState(.loggedOut)
    }
}

@MainActor
final class Dependencies {
    lazy var tabsCoordinatorAdapter = TabsCoordinatorAdapter()
    lazy var rootRouterAdapter = RootRouterAdapter()
    lazy var themeService = UserDefaultsThemeService()
    lazy var themeStore = ThemeStore(themeService: themeService)
    lazy var snapshotService = UserDefaultsRestorableSnapshotService()
    lazy var authStateService = AuthStateProvider()
    lazy var authService = AuthStateServiceMock(service: authStateService)
    lazy var floatingStackStore = FloatingStackStore(clock: ContinuousClock())
    lazy var accountCoordinatorFactory = DefaultAccountCoordinatorFactory()
    lazy var homeCoordinatorFactory = DefaultHomeCoordinatorFactory(tabsCoordinatorAdapter: tabsCoordinatorAdapter)
    lazy var tabsCoordinatorFactory = DefaultTabsCoordinatorFactory(
        authStateService: authStateService,
        homeCoordinatorFactory: homeCoordinatorFactory,
        routerAdapter: rootRouterAdapter,
        tabsCoordinatorAdapter: tabsCoordinatorAdapter
    )
    lazy var rootCoordinatorFactory = DefaultRootCoordinatorFactory(
        authStateService: authStateService,
        authService: authService,
        accountCoordinatorFactory: accountCoordinatorFactory,
        tabsCoordinatorFactory: tabsCoordinatorFactory,
        themeService: themeService,
        routerAdapter: rootRouterAdapter,
        floatingStackStore: floatingStackStore,
        tabsCoordinatesAdapter: tabsCoordinatorAdapter
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
