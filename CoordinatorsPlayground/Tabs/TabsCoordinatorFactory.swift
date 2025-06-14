//
//  DefaultTabsCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 25.05.2025..
//

import Foundation

@MainActor
protocol TabsCoordinatorFactory {
    func makeHomeCoordinator(
        onAccountButtonTapped: @escaping () -> Void,
        onLoginButtonTapped: @escaping () -> Void
    ) -> Feature
    
    func makeSearchCoordinator(
        onAccountButtonTapped: @escaping () -> Void,
        onLoginButtonTapped: @escaping () -> Void
    ) -> Feature
    
    func makeSettingsCoordinator() -> Feature
}

struct DefaultTabsCoordinatorFactory: TabsCoordinatorFactory {
    let authStateService: AuthStateStreamService
    let homeCoordinatorFactory: DefaultHomeCoordinatorFactory
    let settingsCoordinatorFactory: DefaultSettingsCoordinatorFactory
    let routerAdapter: RootRouterAdapter
    let tabsCoordinatorAdapter: TabsCoordinatorAdapter
    let navigationObserver: NavigationObserver
    
    func makeHomeCoordinator(
        onAccountButtonTapped: @escaping () -> Void,
        onLoginButtonTapped: @escaping () -> Void
    ) -> Feature {
        let router = DefaultRouter<HomeStep>()
        let restorer = DefaultRestorer<HomeState>()
        router.onUnhandledRoute = routerAdapter.onUnhandledRoute
        let store = HomeCoordinatorStore(
            authStateService: authStateService,
            factory: homeCoordinatorFactory,
            router: LoggingRouterDecorator(decorating: router),
            restorer: LoggingRestorerDecorator(wrapping: restorer)
        )
        store.onAccountButtonTapped = onAccountButtonTapped
        store.onLoginButtonTapped = onLoginButtonTapped
        store.onPopped = tabsCoordinatorAdapter.handlePop
        
        navigationObserver.observe(observable: store, path: \.$path, destination: \.$destination)
        
        let view = HomeCoordinator(store: store)
        return Feature(view: view, store: store)
    }
    
    func makeSearchCoordinator(
        onAccountButtonTapped: @escaping () -> Void,
        onLoginButtonTapped: @escaping () -> Void
    ) -> Feature {
        let router = DefaultRouter<SearchStep>()
        let store = SearchCoordinatorStore(
            authStateService: authStateService,
            router: LoggingRouterDecorator(decorating: router)
        )
        store.onAccountButtonTapped = onAccountButtonTapped
        store.onLoginButtonTapped = onLoginButtonTapped
        router.onUnhandledRoute = routerAdapter.onUnhandledRoute
        navigationObserver.observe(observable: store, state: \.$tab)
        let view = SearchCoordinator(store: store)
        return Feature(view: view, store: store)
    }
    
    func makeSettingsCoordinator() -> Feature {
        let store = SettingsCoordinatorStore(factory: settingsCoordinatorFactory)
        let view = SettingsCoordinator(store: store)
        return Feature(view: view, store: store)
    }
}
