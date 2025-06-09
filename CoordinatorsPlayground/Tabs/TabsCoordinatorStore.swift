//
//  TabsCoordinatorStore.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import Foundation

@MainActor
class TabsCoordinatorStore: ObservableObject, TabNavigationObservable {
    enum Tab: CaseIterable, Codable {
        case home
        case second
    }
    
    @Published private(set) var tab: Tab
    @Published private(set) var isTabBarVisible: Bool = true
    
    private(set) var tabFeatures: [Tab: Feature] = [:]
    
    var onAccountButtonTapped: () -> Void = unimplemented()
    var onLoginButtonTapped: () -> Void = unimplemented()
    
    private let factory: TabsCoordinatorFactory
    let router: any Router<TabsStep>
    let restorer: any Restorer<TabsState>
    
    init(selectedTab: Tab, factory: TabsCoordinatorFactory, router: any Router<TabsStep>, restorer: any Restorer<TabsState>) {
        self.factory = factory
        self.router = router
        self.restorer = restorer
        self.tab = .second
        
        Tab.allCases.forEach { makeFeature(for: $0) }
        
        router.setup(using: self, childRoutables: { [weak self] in
            guard let self else { return [] }
            return self.tabFeatures.values.compactMap { $0.cast() }
        })
        
        restorer.setup(using: self, childRestorables: { [weak self] in
            guard let self else { return [] }
            return self.tabFeatures.values.compactMap { $0.cast() }
        })
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
        case .second:
            break
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
    
    private func show(tab: Tab) {
        self.tab = tab
    }
}

extension TabsCoordinatorStore: Routable {
    func handle(step: TabsStep) async {
        switch step {
        case .change(let tab):
            switch tab {
            case .home:
                show(tab: .home)
            case .profile:
                show(tab: .second)
            }
        }
    }
}

extension TabsCoordinatorStore: Restorable {
    func captureState() async -> TabsState {
        return .init(tab: tab)
    }
    
    func restore(state: TabsState) async {
        show(tab: state.tab)
    }
}

struct TabsState: Codable {
    let tab: TabsCoordinatorStore.Tab
}

enum TabsStep: Decodable {
    enum Tab: Decodable {
        case home
        case profile
    }
    
    case change(tab: Tab)
}
