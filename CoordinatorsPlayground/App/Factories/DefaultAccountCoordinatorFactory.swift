//
//  DefaultAccountCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 17.06.2025..
//

import Foundation

struct DefaultAccountCoordinatorFactory: AccountCoordinatorFactory {
    let authService: DefaultAuthService
    
    func makeRootScreen(
        onDetailsButtonTapped: @escaping () -> Void,
        onHelpButtonTapped: @escaping () -> Void,
        onLogoutFinished: @escaping () -> Void
    ) -> Feature {
        let store = AccountRootStore(logoutService: authService)
        store.onDetailsButtonTapped = onDetailsButtonTapped
        store.onHelpButtonTapped = onHelpButtonTapped
        store.onLogoutFinished = onLogoutFinished
        let view = AccountRootScreen(store: store)
        return Feature(view: view, store: store)
    }
    
    func makeDetailsScreen() -> Feature {
        let store = AccountDetailsStore()
        let view = AccountDetailsScreen(store: store).navigationTitle(store.title)
        return Feature(view: view, store: store)
    }
    
    func makeHelpScreen(onDismiss: @escaping () -> Void) -> Feature {
        let store = AccountHelpStore()
        store.onDismiss = onDismiss
        let view = AccountHelpScreen(store: store).navigationTitle(store.title)
        return Feature(view: view, store: store)
    }
}
