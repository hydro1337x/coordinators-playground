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
            if let store = store.store(for: .home, of: HomeCoordinatorStore.self) {
                HomeCoordinator(store: store)
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
    private var stores: [Tab: AnyObject] = [:]
    
    var onAccountButtonTapped: () -> Void = unimplemented()
    var onLoginButtonTapped: () -> Void = unimplemented()
    var onUnhandledRoute: (Route) async -> Bool = unimplemented(return: false)
    
    private let authStateService: AuthStateProvider
    
    init(selectedTab: Tab, authStateService: AuthStateProvider) {
        self.authStateService = authStateService
        self.tab = selectedTab
        
        Tab.allCases.forEach { makeStore(for: $0) }
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
    
    func store<T>(for tab: Tab, of type: T.Type) -> T? {
        stores[tab] as? T
    }
    
    private func makeStore(for tab: Tab) {
        switch tab {
        case .home:
            let store = HomeCoordinatorStore(path: [], authStateService: authStateService)
            store.onAccountButtonTapped = { [weak self] in
                self?.onAccountButtonTapped()
            }
            store.onLoginButtonTapped = { [weak self] in
                self?.onLoginButtonTapped()
            }
            store.onUnhandledRoute = { [weak self] route in
                guard let self else { return false }
                return await self.onUnhandledRoute(route)
            }
            stores[tab] = store
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
        
        let routers = stores.values.compactMap { $0 as? Router }
        
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
