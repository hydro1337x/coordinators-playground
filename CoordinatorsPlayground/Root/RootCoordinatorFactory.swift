//
//  DefaultRootCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 25.05.2025..
//

import Foundation
import SwiftUI

@MainActor
protocol RootCoordinatorFactory {
    func makeAuthCoordinator(onFinished: @escaping () -> Void) -> Feature
    func makeAccountCoordinator(onFinished: @escaping () -> Void) -> Feature
    func makeOnboardingCoordinator(onFinished: @escaping () -> Void) -> Feature
    func makeMainTabsCoordinator(onAccountButtonTapped: @escaping () -> Void, onLoginButtonTapped: @escaping () -> Void) -> Feature
    func makeSpecialFlowCoordinator(onMainFlowButtonTapped: @escaping () -> Void) -> Feature
}

struct DefaultRootCoordinatorFactory: RootCoordinatorFactory {
    let authStateService: AuthStateStreamService
    let authService: AuthService
    let accountCoordinatorFactory: DefaultAccountCoordinatorFactory
    let mainTabsCoordinatorFactory: DefaultMainTabsCoordinatorFactory
    let themeService: UserDefaultsThemeService
    let routerAdapter: RootRouterAdapter
    let floatingStackStore: FloatingStackStore
    let mainTabsCoordinatorAdapter: MainTabsCoordinatorAdapter
    let navigationObserver: NavigationObserver
    
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
            factory: accountCoordinatorFactory,
            router: LoggingRouterDecorator(decorating: router),
            restorer: LoggingRestorerDecorator(wrapping: restorer)
        )
        store.onFinished = onFinished
        navigationObserver.observe(observable: store, path: \.$path, destination: \.$destination)
        let view = AccountCoordinator(
            store: store,
            makeFloatingStack: { [floatingStackStore] in
                AnyView(FloatingStack(store: floatingStackStore))
            }
        )
        return Feature(view: view, store: store)
    }
    
    func makeOnboardingCoordinator(onFinished: @escaping () -> Void) -> Feature {
        let store = OnboardingCoordinatorStore()
        store.onFinished = onFinished
        navigationObserver.observe(observable: store, state: \.$tab)
        let view = OnboardingCoordinator(store: store)
        return Feature(view: view, store: store)
    }
    
    func makeMainTabsCoordinator(onAccountButtonTapped: @escaping () -> Void, onLoginButtonTapped: @escaping () -> Void) -> Feature {
        let router = DefaultRouter<TabsStep>()
        let restorer = DefaultRestorer<TabsState>()
        router.onUnhandledRoute = routerAdapter.onUnhandledRoute
        let store = MainTabsCoordinatorStore(
            selectedTab: .search,
            activeTabs: mainTabsCoordinatorAdapter.activeTabs,
            factory: mainTabsCoordinatorFactory,
            router: LoggingRouterDecorator(decorating: router),
            restorer: LoggingRestorerDecorator(wrapping: restorer)
        )
        mainTabsCoordinatorAdapter.onHideTabBar = { [weak store] in
            store?.hideTabBar()
        }
        mainTabsCoordinatorAdapter.onShowTabBar = { [weak store] in
            store?.showTabBar()
        }
        mainTabsCoordinatorAdapter.onActiveTabsChanged = { [weak store] tabs in
            store?.setActiveTabs(tabs)
        }
        store.onAccountButtonTapped = onAccountButtonTapped
        store.onLoginButtonTapped = onLoginButtonTapped
        navigationObserver.observe(observable: store, state: \.$tab)
        let view = MainTabsCoordinator(
            store: store,
            makeFloatingStack: { [floatingStackStore] in
                AnyView(FloatingStack(store: floatingStackStore))
            }
        )
        return Feature(view: view, store: store)
    }
    
    func makeSpecialFlowCoordinator(onMainFlowButtonTapped: @escaping () -> Void) -> Feature {
        let store = SpecialFlowCoordinatorStore()
        store.onMainFlowButtonTapped = onMainFlowButtonTapped
        let view = SpecialFlowCoordinator(store: store)
        return Feature(view: view, store: store)
    }
}
