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
    }
}

@MainActor
class TabsCoordinatorStore: ObservableObject {
    enum Tab: CaseIterable {
        case home
        case second
    }
    
    @Published var tab: Tab
    private(set) var tabFeatures: [Tab: Feature] = [:]
    private var routingHandlers: [(Route) async -> Void] = []
    
    var onAccountButtonTapped: () -> Void = unimplemented()
    var onLoginButtonTapped: () -> Void = unimplemented()
    var onUnhandledRoute: (Route) async -> Bool = unimplemented(return: false)
    
    private let factory: TabsCoordinatorFactory
    
    init(selectedTab: Tab, factory: TabsCoordinatorFactory) {
        self.factory = factory
        self.tab = selectedTab
        
        Tab.allCases.forEach { makeFeature(for: $0) }
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
                },
                onUnhandledRoute: { [weak self] route in
                    guard let self else { return false }
                    return await self.onUnhandledRoute(route)
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

extension TabsCoordinatorStore: Router {
    func handle(route: Route) async -> Bool {
        let didHandleStep = await handle(step: route.step)
        
        guard didHandleStep else {
            return await onUnhandledRoute(route)
        }
        
        let routers = tabFeatures.values.compactMap { $0.as(type: Router.self) }
        
        return await handle(childRoutes: route.children, using: routers)
    }
    
    private func handle(step: Route.Step) async -> Bool {
        switch step {
        case .tab(let tab):
            switch tab {
            case .home:
                show(tab: .home)
                return true
            case .profile:
                show(tab: .second)
                return true
            }
        case .flow, .present, .push:
            return false
        }
    }
}
