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
class TabsCoordinatorStore: ObservableObject, Routable {
    enum Tab: CaseIterable {
        case home
        case second
    }
    
    @Published var tab: Tab
    private var stores: [Tab: AnyObject] = [:]
    
    var onAccountButtonTapped: () -> Void = {}
    var onLoginButtonTapped: () -> Void = {}
    
    private let authStateStore: AuthStateStore
    
    init(selectedTab: Tab, authStateStore: AuthStateStore) {
        self.authStateStore = authStateStore
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
            let store = HomeCoordinatorStore(path: [], authStateStore: authStateStore)
            store.onAccountButtonTapped = { [weak self] in
                self?.onAccountButtonTapped()
            }
            store.onLoginButtonTapped = { [weak self] in
                self?.onLoginButtonTapped()
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
    
    func handle(routes: [Route]) {
        guard let route = routes.first else { return }
        let routes = Array(routes.dropFirst())
        
        switch route {
        case .home:
            show(tab: .home)
        default:
            break
        }
        
        stores
            .values
            .compactMap { $0 as? Routable }
            .forEach { $0.handle(routes: routes) }
    }
}
