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

class TabsCoordinatorStore: ObservableObject, Routable {
    enum Tab: CaseIterable {
        case home
        case second
    }
    
    @Published var tab: Tab
    private var stores: [Tab: AnyObject] = [:]
    
    var onFinished: () -> Void = {}
    
    init(selectedTab: Tab) {
        self.tab = selectedTab
        
        Tab.allCases.forEach(makeStore(for:))
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
            let store = HomeCoordinatorStore(path: [])
            store.onFinished = { [weak self] in
                // Logout
                self?.onFinished()
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
    
    func route(deepLinks: [DeepLink]) {
        guard let deepLink = deepLinks.first else { return }
        let deepLinks = Array(deepLinks.dropFirst())
        
        switch deepLink {
        case .home:
            show(tab: .home)
        default:
            break
        }
        
        stores
            .values
            .compactMap { $0 as? Routable }
            .forEach { $0.route(deepLinks: deepLinks) }
    }
}
