//
//  HomeCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import SwiftUI

struct HomeCoordinator: View {
    @ObservedObject var store: HomeCoordinatorStore
    
    var body: some View {
        NavigationStack(
            path: .init(
                get: { store.path },
                set: { store.handlePathChanged($0) }
            )
        ) {
            HomeScreen(store: store.homeScreenStore)
                .navigationDestination(for: HomeCoordinatorStore.Path.self) { path in
                    switch path {
                    case .screenA:
                        makeView(for: path, with: StoreA.self) { store in
                            ScreenA(store: store)
                                .navigationTitle(store.title)
                                .toolbar(content: toolbarButton)
                        }
                    case .screenB:
                        makeView(for: path, with: StoreB.self) { store in
                            ScreenB(store: store)
                                .navigationTitle(store.title)
                                .toolbar(content: toolbarButton)
                        }
                    case .screenC:
                        makeView(for: path, with: StoreC.self) { store in
                            ScreenC(store: store)
                                .navigationTitle(store.title)
                                .toolbar(content: toolbarButton)
                        }
                    }
                }
                .navigationTitle(store.homeScreenStore.title)
                .toolbar(content: toolbarButton)
        }
        .task {
            await store.bindObservers()
        }
    }

    func toolbarButton() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            switch store.authState {
            case .loggedIn:
                Button("Account") {
                    store.handleAccountButtonTapped()
                }
            case .loginInProgress:
                ProgressView()
                    .progressViewStyle(.circular)
            case .loggedOut:
                Button("Login") {
                    store.handleLoginButtonTapped()
                }
            case nil:
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    func makeView<Store, Content: View>(
        for path: HomeCoordinatorStore.Path,
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
class HomeCoordinatorStore: ObservableObject, Routable {
    enum Path: Hashable {
        case screenA
        case screenB(id: Int)
        case screenC
    }
    
    @Published private(set) var path: [Path] = []
    @Published private(set) var authState: AuthState?
    private var stores: [Path: AnyObject] = [:]
    let homeScreenStore: HomeScreenStore
    
    var onAccountButtonTapped: () -> Void = {}
    var onLoginButtonTapped: () -> Void = {}
    
    private let authStateStore: AuthStateStore
    
    init(path: [Path], authStateStore: AuthStateStore) {
        self.authStateStore = authStateStore
        self.homeScreenStore = HomeScreenStore()
        path.forEach { makeStore(for:$0) }
        
        self.path = path
        
        homeScreenStore.onButtonTap = { [weak self] in
            self?.push(path: .screenA)
        }
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
    
    func store<T>(for path: Path, of type: T.Type) -> T? {
        return stores[path] as? T
    }
    
    func handlePathChanged(_ newPath: [Path]) {
        if newPath.count < path.count {
            let poppedPath = Array(path.suffix(from: newPath.count))
            poppedPath.forEach { stores[$0] = nil }
        }
        
        path = newPath
    }
    
    func handleAccountButtonTapped() {
        onAccountButtonTapped()
    }
    
    func handleLoginButtonTapped() {
        onLoginButtonTapped()
    }
    
    func bindObservers() async {
        for await state in await authStateStore.values {
            authState = state
        }
    }
    
    private func makeStore(for path: Path) {
        guard stores[path] == nil else { return }
        
        switch path {
        case .screenA:
            let store = StoreA()
            store.onButtonTap = { [weak self] in
                self?.push(path: .screenB(id: 1))
            }
            stores[path] = store
        case .screenB(let id):
            let store = StoreB(id: id)
            
            store.onPushClone = { [weak self] nextId in
                self?.push(path: .screenB(id: nextId))
            }
            
            store.onPushNext = { [weak self] in
                self?.push(path: .screenC)
            }
            
            stores[path] = store
        case .screenC:
            let store = StoreC()
            
            store.onBack = { [weak self] in
                self?.pop()
            }
            
            stores[path] = store
        }
    }
    
    private func push(path: Path) {
        makeStore(for: path)
        self.path.append(path)
    }
    
    private func pop() {
        guard !path.isEmpty else { return }
        
        let lastPath = path.removeLast()
        
        stores[lastPath] = nil
    }
    
    func handle(routes: [Route]) {
        guard let route = routes.first else { return }
        let routes = Array(routes.dropFirst())
        
        // Recursively execute route(deepLinks:) to check if there are remaining screens for stack pushing
        switch route {
        case .screenA:
            push(path: .screenA)
            handle(routes: routes)
        case .screenB(id: let id):
            push(path: .screenB(id: id))
            handle(routes: routes)
        case .screenC:
            push(path: .screenC)
            handle(routes: routes)
        default:
            break
        }
        
        stores
            .values
            .compactMap { $0 as? Routable }
            .forEach { $0.handle(routes: routes) }
    }
}


