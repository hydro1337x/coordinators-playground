//
//  AccountCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 12.05.2025..
//

import SwiftUI

struct AccountCoordinator: View {
    @ObservedObject var store: AccountCoordinatorStore
    
    var body: some View {
        NavigationStack(path: .init(get: { store.path }, set: { store.handlePathChanged($0) })) {
            VStack {
                Text("User Bob Account")
                Spacer()
                Button("Logout") {
                    Task { await store.handleLogoutButtonTapped() }
                }
            }
            .navigationDestination(for: AccountCoordinatorStore.Path.self) { path in
                switch path {
                case .details:
                    makeView(for: path, with: AccountDetailsStore.self) { store in
                        AccountDetailsScreen(store: store)
                            .navigationTitle(store.title)
                    }
                }
            }
            .navigationTitle("Account")
        }
    }
    
    @ViewBuilder
    func makeView<Store, Content: View>(
        for path: AccountCoordinatorStore.Path,
        with storeType: Store.Type,
        content: (Store) -> Content
    ) -> some View {
        if let store = store.store(for: path, of: Store.self) {
            content(store)
        } else {
            Text("Something went wrong")
        }
    }
}

@MainActor
class AccountCoordinatorStore: ObservableObject {
    enum Path {
        case details
    }
    
    @Published private(set) var path: [Path] = []
    private var pathStores: [Path: AnyObject] = [:]
    
    var onFinished: () -> Void = unimplemented()
    var onUnhandledRoute: (Route) async -> Bool = unimplemented(return: false)
    
    private let authStateStore: AuthStateStore
    
    init(authStateStore: AuthStateStore) {
        self.authStateStore = authStateStore
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
    
    func store<T>(for path: Path, of type: T.Type) -> T? {
        return pathStores[path] as? T
    }
    
    func handlePathChanged(_ newPath: [Path]) {
        if newPath.count < path.count {
            let poppedPath = Array(path.suffix(from: newPath.count))
            poppedPath.forEach { pathStores[$0] = nil }
        }
        
        path = newPath
    }
    
    private func makeStore(for path: Path) {
        guard pathStores[path] == nil else { return }
        
        switch path {
        case .details:
            let store = AccountDetailsStore()
            pathStores[path] = store
        }
    }
    
    func handleLogoutButtonTapped() async {
        await authStateStore.setState(.loggedOut)
        
        onFinished()
    }
    
    private func push(path: Path) {
        makeStore(for: path)
        self.path.append(path)
    }
}

extension AccountCoordinatorStore: Router {
    func handle(route: Route) async -> Bool {
        await handle(step: route.step)
    }
    
    private func handle(step: Route.Step) async -> Bool {
        switch step {
        case .push(let path):
            switch path {
            case .accountDetails:
                push(path: .details)
                return true
            default:
                return false
            }
        case .flow, .tab, .present:
            return false
        }
    }
}
