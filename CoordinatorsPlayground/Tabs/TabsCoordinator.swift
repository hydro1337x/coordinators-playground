//
//  TabsCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import SwiftUI

struct TabsCoordinator: View {
    @ObservedObject var store: TabsCoordinatorStore
    
    var body: some View {
        TabView(selection: .init(get: { store.tab }, set: { store.handleTabChanged($0) })) {
            Group {
                if let tabFeature = store.tabFeatures[.home] {
                    tabFeature
                        .tag(TabsCoordinatorStore.Tab.home)
                        .tabItem {
                            Image(systemName: "list.bullet")
                        }
                }
                
                Text("Second Tab View")
                    .tag(TabsCoordinatorStore.Tab.second)
                    .tabItem {
                        Image(systemName: "paperplane")
                    }
            }
            .toolbarBackground(.white, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
    }
}

@MainActor
class TabsCoordinatorStore: ObservableObject {
    enum Tab: CaseIterable, Codable {
        case home
        case second
    }
    
    @Published var tab: Tab
    private(set) var tabFeatures: [Tab: Feature] = [:]
    private var routingHandlers: [(Route) async -> Void] = []
    
    var onAccountButtonTapped: () -> Void = unimplemented()
    var onLoginButtonTapped: () -> Void = unimplemented()
    
    private let factory: TabsCoordinatorFactory
    let router: any Router<TabsStep>
    let restorer: any Restorer<TabsState>
    
    init(selectedTab: Tab, factory: TabsCoordinatorFactory, router: any Router<TabsStep>, restorer: any Restorer<TabsState>) {
        self.factory = factory
        self.router = router
        self.restorer = restorer
        self.tab = selectedTab
        
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
