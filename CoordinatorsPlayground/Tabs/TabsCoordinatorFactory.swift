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
    
    func makeHomeCoordinator(
        onAccountButtonTapped: @escaping () -> Void,
        onLoginButtonTapped: @escaping () -> Void,
        onUnhandledRoute: @escaping (Route) async -> Bool
    ) -> Feature {
        let store = HomeCoordinatorStore(
            path: [],
            authStateService: authStateService,
            factory: homeCoordinatorFactory
        )
        store.onAccountButtonTapped = onAccountButtonTapped
        store.onLoginButtonTapped = onLoginButtonTapped
        store.onUnhandledRoute = onUnhandledRoute
        let view = HomeCoordinator(store: store)
        return Feature(view: view, store: store)
    }
}
