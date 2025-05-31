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
    let themeService: UserDefaultsThemeService
    let routerAdapter: RootRouterAdapter
    let floatingStackStore: FloatingStackStore
    
    func makeAuthCoordinator(onFinished: @escaping () -> Void) -> Feature {
        let store = AuthCoordinatorStore(authStateService: authStateService, authService: authService)
        store.onFinished = onFinished
        let view = AuthCoordinator(store: store)
        return Feature(view: view, store: store)
    }
    
    func makeAccountCoordinator(onFinished: @escaping () -> Void) -> Feature {
        let router = DefaultRouter<AccountStep>()
        let restorer = DefaultRestorer<AccountState>()
        router.onUnhandledRoute = routerAdapter.onUnhandledRoute
        let store = AccountCoordinatorStore(
            logoutService: authService,
            themeService: themeService,
            factory: accountCoordinatorFactory,
            router: LoggingRouterDecorator(decorating: router),
            restorer: LoggingRestorerDecorator(wrapping: restorer)
        )
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
    
    func makeTabsCoordinator(onAccountButtonTapped: @escaping () -> Void, onLoginButtonTapped: @escaping () -> Void) -> Feature {
        let router = DefaultRouter<TabsStep>()
        let restorer = DefaultRestorer<TabsState>()
        router.onUnhandledRoute = routerAdapter.onUnhandledRoute
        let store = TabsCoordinatorStore(
            selectedTab: .second,
            factory: tabsCoordinatorFactory,
            router: LoggingRouterDecorator(decorating: router),
            restorer: LoggingRestorerDecorator(wrapping: restorer)
        )
        store.onAccountButtonTapped = onAccountButtonTapped
        store.onLoginButtonTapped = onLoginButtonTapped
        let view = TabsCoordinator(store: store)
        return Feature(view: view, store: store)
    }
}
