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
        .sheet(
            item: .init(get: { store.destination }, set: { store.handleDestinationChanged($0) }),
            content: { destination in
                switch destination {
                case .screenB:
                    makeView(for: destination, with: StoreB.self, content: ScreenB.init)
                }
            }
        )
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
        for destination: HomeCoordinatorStore.Destination,
        with storeType: Store.Type,
        content: (Store) -> Content
    ) -> some View {
        if let store = store.store(for: destination, of: Store.self) {
            content(store)
        } else {
            Text("Something went wrong")
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
class HomeCoordinatorStore: ObservableObject {
    enum Path: Hashable {
        case screenA
        case screenB(id: Int)
        case screenC
    }
    
    enum Destination: Hashable, Identifiable {
        case screenB(id: Int)
        
        var id: AnyHashable { self }
    }
    
    @Published private(set) var destination: Destination?
    @Published private(set) var path: [Path] = []
    @Published private(set) var authState: AuthState?
    private var destinationStore: AnyObject?
    private var pathStores: [Path: AnyObject] = [:]
    let homeScreenStore: HomeScreenStore
    
    var onAccountButtonTapped: () -> Void = {}
    var onLoginButtonTapped: () -> Void = {}
    var onUnhandeledRoute: ((Route) async -> Void)?
    
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
    
    func store<T>(for destination: Destination, of type: T.Type) -> T? {
        return destinationStore as? T
    }
    
    func store<T>(for path: Path, of type: T.Type) -> T? {
        return pathStores[path] as? T
    }
    
    func handleDestinationChanged(_ destination: Destination?) {
        if let destination {
            self.destination = destination
        } else {
            destinationStore = nil
            self.destination = nil
        }
    }
    
    func handlePathChanged(_ newPath: [Path]) {
        if newPath.count < path.count {
            let poppedPath = Array(path.suffix(from: newPath.count))
            poppedPath.forEach { pathStores[$0] = nil }
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
    
    func makeStore(for destination: Destination) {
        switch destination {
        case .screenB(let id):
            let store = StoreB(id: id)
            
            store.onPushClone = { [weak self] nextId in
                self?.push(path: .screenB(id: nextId))
            }
            
            store.onPushNext = { [weak self] in
                self?.push(path: .screenC)
            }
            
            destinationStore = store
        }
    }
    
    private func makeStore(for path: Path) {
        guard pathStores[path] == nil else { return }
        
        switch path {
        case .screenA:
            let store = StoreA()
            store.onButtonTap = { [weak self] in
                self?.push(path: .screenB(id: 1))
            }
            pathStores[path] = store
        case .screenB(let id):
            let store = StoreB(id: id)
            
            store.onPushClone = { [weak self] nextId in
                self?.push(path: .screenB(id: nextId))
            }
            
            store.onPushNext = { [weak self] in
                self?.push(path: .screenC)
            }
            
            pathStores[path] = store
        case .screenC:
            let store = StoreC()
            
            store.onBack = { [weak self] in
                self?.pop()
            }
            
            pathStores[path] = store
        }
    }
    
    private func present(destination: Destination) {
        switch destination {
        case .screenB:
            makeStore(for: destination)
            self.destination = destination
        }
    }
    
    private func push(path: Path) {
        makeStore(for: path)
        self.path.append(path)
    }
    
    private func pop() {
        guard !path.isEmpty else { return }
        
        let lastPath = path.removeLast()
        
        pathStores[lastPath] = nil
    }
}

extension HomeCoordinatorStore: Router {
    func handle(route: Route) async -> Bool {
        let didHandleStep = await handle(step: route.step)
        
        guard didHandleStep else { return false }
        
        let routers = [
            [destinationStore as? Router],
            pathStores.values.map { $0 as? Router }
        ]
        .flatMap { $0 }
        .compactMap { $0 }
        
        
        for route in route.children {
            var didHandleStep = false
            
            for router in routers {
                if await router.handle(route: route) {
                    didHandleStep = true
                    break
                }
            }
            
            // If none of the child routers handled this child route
            if !didHandleStep {
                print("⚠️ Unhandled route step: \(route.step)")
                return false
            }
        }
        
        return true
    }
    
    private func handle(step: Route.Step) async -> Bool {
        switch step {
        case .present(let destination):
            switch destination {
            case .screenB(id: let id):
                present(destination: .screenB(id: id))
                return true
            default:
                return false
            }
        case .push(let path):
            switch path {
            case .screenA:
                push(path: .screenA)
                return true
            case .screenB(let id):
                push(path: .screenB(id: id))
                return true
            case .screenC:
                push(path: .screenC)
                return true
            default:
                return false
            }
        case .flow, .tab:
            return false
        }
    }
}

