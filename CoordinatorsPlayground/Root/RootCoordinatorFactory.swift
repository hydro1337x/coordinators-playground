//
//  RootCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 25.05.2025..
//

import Foundation
import SwiftUI

@MainActor
struct RootCoordinatorFactory {
    let authStateService: AuthStateStreamService
    let authService: AuthTokenLoginService & LogoutService
    let accountCoordinatorFactory: AccountCoordinatorFactory
    let tabsCoordinatorFactory: TabsCoordinatorFactory
    let themeManager: SetThemeService
    
    func makeAuthCoordinator(onFinished: @escaping () -> Void) -> Feature {
        let store = AuthCoordinatorStore(authStateService: authStateService, authService: authService)
        store.onFinished = onFinished
        let view = AuthCoordinator(store: store)
        return Feature(view: view, store: store)
    }
    
    func makeAccountCoordinator(onFinished: @escaping () -> Void) -> Feature {
        let store = AccountCoordinatorStore(logoutService: authService, themeService: themeManager, factory: accountCoordinatorFactory)
        store.onFinished = onFinished
        let view = AccountCoordinator(store: store)
        return Feature(view: view, store: store)
    }
    
    func makeOnboardingCoordinator(onFinished: @escaping () -> Void) -> Feature {
        let store = OnboardingCoordinatorStore()
        store.onFinished = onFinished
        let view = OnboardingCoordinator(store: store)
        return Feature(view: view, store: store)
    }
    
    func makeTabsCoordinator(onAccountButtonTapped: @escaping () -> Void, onLoginButtonTapped: @escaping () -> Void, onUnhandledRoute: @escaping (Route) async -> Bool) -> Feature {
        let store = TabsCoordinatorStore(
            selectedTab: .second,
            factory: tabsCoordinatorFactory
        )
        store.onAccountButtonTapped = onAccountButtonTapped
        store.onLoginButtonTapped = onLoginButtonTapped
        store.onUnhandledRoute = onUnhandledRoute
        let view = TabsCoordinator(store: store)
        return Feature(view: view, store: store)
    }
}
