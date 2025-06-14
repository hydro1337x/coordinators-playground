//
//  MainTabsCoordinatorStore.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import Foundation
import SwiftUI

@MainActor
class MainTabsCoordinatorStore: ObservableObject, TabsCoordinator {
    @Published private(set) var tab: Tab
    @Published private(set) var isTabBarVisible: Bool = true
    @Published private(set) var activeTabs: [Tab]
    
    private(set) var tabFeatures: [Tab: Feature] = [:]
    
    var onAccountButtonTapped: () -> Void = unimplemented()
    var onLoginButtonTapped: () -> Void = unimplemented()
    
    private let factory: MainTabsCoordinatorFactory
    let router: any Router<TabsStep>
    let restorer: any Restorer<TabsState>
    
    init(selectedTab: Tab, activeTabs: [Tab], factory: MainTabsCoordinatorFactory, router: any Router<TabsStep>, restorer: any Restorer<TabsState>) {
        self.factory = factory
        self.router = router
        self.restorer = restorer
        self.tab = .search
        self.activeTabs = activeTabs
        
        activeTabs.forEach { makeFeature(for: $0) }
        
        router.register(routable: self)
        restorer.register(restorable: self)
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
    
    private func makeFeature(for tab: Tab) {
        switch tab {
        case .home:
            let feature = factory.makeHomeCoordinator(
                onAccountButtonTapped: { [weak self] in
                    self?.onAccountButtonTapped()
                },
                onLoginButtonTapped: { [weak self] in
                    self?.onLoginButtonTapped()
                }
            )
            tabFeatures[tab] = feature
        case .search:
            let feature = factory.makeSearchCoordinator(
                onAccountButtonTapped: { [weak self] in
                    self?.onAccountButtonTapped()
                },
                onLoginButtonTapped: { [weak self] in
                    self?.onLoginButtonTapped()
                }
            )
            tabFeatures[tab] = feature
        case .settings:
            let feature = factory.makeSettingsCoordinator()
            tabFeatures[tab] = feature
        }
    }
    
    func hideTabBar() {
        isTabBarVisible = false
    }
    
    func showTabBar() {
        isTabBarVisible = true
    }
    
    func handleTabChanged(_ tab: Tab) {
        self.tab = tab
    }
    
    func setActiveTabs(_ tabs: [Tab]) {
        self.activeTabs = tabs
    }
    
    private func show(tab: Tab) {
        self.tab = tab
    }
}

enum Tab: CaseIterable, Codable {
    case home
    case search
    case settings
}

extension MainTabsCoordinatorStore: Routable {
    func handle(step: TabsStep) async {
        switch step {
        case .change(let tab):
            switch tab {
            case .home:
                show(tab: .home)
            case .search:
                show(tab: .search)
            case .settings:
                show(tab: .settings)
            }
        }
    }
}

extension MainTabsCoordinatorStore: Restorable {
    func captureState() async -> TabsState {
        return .init(tab: tab)
    }
    
    func restore(state: TabsState) async {
        show(tab: state.tab)
    }
}

struct TabsState: Codable {
    let tab: MainTabsCoordinatorStore.Tab
}

enum TabsStep: Decodable {
    enum Tab: Decodable {
        case home
        case search
        case settings
    }
    
    case change(tab: Tab)
}
