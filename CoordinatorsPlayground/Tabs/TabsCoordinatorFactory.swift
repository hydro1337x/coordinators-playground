//
//  TabsCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 25.05.2025..
//

import Foundation

@MainActor
struct TabsCoordinatorFactory {
    let authStateService: AuthStateStreamService
    let homeCoordinatorFactory: HomeCoordinatorFactory
    let routerAdapter: RootRouterAdapter
    
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
        let view = HomeCoordinator(store: store)
        return Feature(view: view, store: store)
    }
}
