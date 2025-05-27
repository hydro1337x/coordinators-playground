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
    let homeRouter: any Router<HomeStep>
    
    func makeHomeCoordinator(
        onAccountButtonTapped: @escaping () -> Void,
        onLoginButtonTapped: @escaping () -> Void
    ) -> Feature {
        let store = HomeCoordinatorStore(
            path: [],
            authStateService: authStateService,
            factory: homeCoordinatorFactory,
            router: homeRouter
        )
        store.onAccountButtonTapped = onAccountButtonTapped
        store.onLoginButtonTapped = onLoginButtonTapped
        let view = HomeCoordinator(store: store)
        return Feature(view: view, store: store)
    }
}
