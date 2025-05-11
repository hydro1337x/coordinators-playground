//
//  RootCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import SwiftUI

struct RootCoordinator: View {
    @ObservedObject var store: RootCoordinatorStore
    
    var body: some View {
        Group {
            switch store.flow {
            case .login:
                makeView(for: .login, with: LoginCoordinatorStore.self) {
                    LoginCoordinator(store: $0)
                }
            case .tabs:
                makeView(for: .tabs, with: TabsCoordinatorStore.self) {
                    TabsCoordinator(store: $0)
                }
            case nil:
                Text("Loading..")
            }
        }
    }
    
    @ViewBuilder
    func makeView<Store, Content: View>(
        for flow: RootCoordinatorStore.Flow,
        with storeType: Store.Type,
        content: (Store) -> Content
    ) -> some View {
        if let store = store.store(for: flow, of: Store.self) {
            content(store)
        } else {
            Text("Something went wrong")
        }
    }
}

class RootCoordinatorStore: ObservableObject, Routable {
    enum Flow {
        case login
        case tabs
    }
    
    @Published var flow: Flow?
    private var stores: [Flow: AnyObject] = [:]
    
    init() {
        show(flow: .login)
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
    
    func store<T>(for flow: Flow, of type: T.Type) -> T? {
        stores[flow] as? T
    }
    
    private func makeStore(for flow: Flow) {
        switch flow {
        case .login:
            let store = LoginCoordinatorStore()
            store.onFinished = { [weak self] in
                self?.show(flow: .tabs)
            }
            stores[flow] = store
        case .tabs:
            let store = TabsCoordinatorStore(selectedTab: .home)
            store.onFinished = { [weak self] in
                self?.show(flow: .login)
            }
            stores[flow] = store
        }
    }
    
    private func show(flow: Flow) {
        stores = [:]
        makeStore(for: flow)
        self.flow = flow
    }
    
    func route(deepLinks: [DeepLink]) {
        guard let deepLink = deepLinks.first else { return }
        let deepLinks = Array(deepLinks.dropFirst())
        
        switch deepLink {
        case .login:
            show(flow: .login)
        case .tabs:
            show(flow: .tabs)
        default:
            break
        }
        
        stores
            .values
            .compactMap { $0 as? Routable }
            .forEach { $0.route(deepLinks: deepLinks) }
    }
}

protocol Routable {
    func route(deepLinks: [DeepLink])
}
