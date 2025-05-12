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
        TabsCoordinator(store: store.tabsCoordinatorStore)
            .sheet(item: .init(get: { store.destination }, set: { store.handleDestinationChanged($0) })) { destination in
                switch destination {
                case .auth:
                    makeView(for: destination, with: AuthCoordinatorStore.self, content: AuthCoordinator.init)
                case .account:
                    makeView(for: destination, with: AccountCoordinatorStore.self, content: AccountCoordinator.init)
                }
            }
    }
    
    @ViewBuilder
    func makeView<Store, Content: View>(
        for destination: RootCoordinatorStore.Destination,
        with storeType: Store.Type,
        content: (Store) -> Content
    ) -> some View {
        if let store = store.store(for: destination, of: Store.self) {
            content(store)
        } else {
            Text("Something went wrong")
        }
    }
}

@MainActor
class RootCoordinatorStore: ObservableObject, Routable {
    enum Destination: String, Identifiable {
        case auth
        case account
        
        var id: String { rawValue }
    }
    
    @Published private(set) var destination: Destination?
    let tabsCoordinatorStore: TabsCoordinatorStore
    private var destinationStore: AnyObject?
    
    private let authStateStore: AuthStateStore
    
    init(authStateStore: AuthStateStore) {
        self.authStateStore = authStateStore
        tabsCoordinatorStore = TabsCoordinatorStore(selectedTab: .home, authStateStore: authStateStore)
        
        tabsCoordinatorStore.onAccountButtonTapped = { [weak self] in
            self?.present(destination: .account)
        }
        
        tabsCoordinatorStore.onLoginButtonTapped = { [weak self] in
            self?.present(destination: .auth)
        }
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
    
    func store<T>(for destination: Destination, of type: T.Type) -> T? {
        destinationStore as? T
    }
    
    func handleDestinationChanged(_ destination: Destination?) {
        if destination == nil {
            destinationStore = nil
        }
        self.destination = destination
    }
    
    private func makeStore(for destination: Destination) {
        switch destination {
        case .auth:
            let store = AuthCoordinatorStore(authStateStore: authStateStore)
            store.onFinished = { [weak self] in
                self?.present(destination: .account)
            }
            destinationStore = store
        case .account:
            let store = AccountCoordinatorStore(authStateStore: authStateStore)
            store.onFinished = { [weak self] in
                self?.dismiss()
            }
            destinationStore = store
        }
    }
    
    private func present(destination: Destination) {
        destinationStore = nil
        makeStore(for: destination)
        self.destination = destination
    }
    
    private func dismiss() {
        destinationStore = nil
        self.destination = nil
    }
    
    private func handleAccountRoute() {
        Task {
            let authState = await authStateStore.currentValue
            switch authState {
            case .loggedIn:
                present(destination: .account)
            case .loginInProgress:
                break
            case .loggedOut:
                present(destination: .auth)
            }
        }
    }
    
    func handle(routes: [Route]) {
        guard let route = routes.first else { return }
        
        switch route {
        case .account:
            handleAccountRoute()
        default:
            break
        }
        
        [tabsCoordinatorStore, destinationStore]
            .compactMap { $0 as? Routable }
            .forEach { $0.handle(routes: routes) }
    }
}

@MainActor
protocol Routable {
    func handle(routes: [Route])
}

enum AuthState {
    case loggedIn
    case loginInProgress
    case loggedOut
}

import Combine

actor AuthStateStore {
    private struct Subscriber {
        let id: UUID
        let continuation: AsyncStream<AuthState>.Continuation
    }
    
    private var state: AuthState = .loggedOut
    private var subscribers: [Subscriber] = []
    
    var currentValue: AuthState {
        state
    }
    
    var values: AsyncStream<AuthState> {
        let id = UUID()
        
        return AsyncStream { continuation in
            // Yield the current value immediately
            continuation.yield(state)
            
            let subscriber = Subscriber(id: id, continuation: continuation)
            subscribers.append(subscriber)
            
            continuation.onTermination = { [weak self] _ in
                Task {
                    await self?.removeSubscribers(where: id)
                }
            }
        }
    }
    
    func removeSubscribers(where id: UUID) {
        print("Removing subscribers for \(id)")
        subscribers.removeAll { $0.id == id }
    }
    
    func setState(_ newState: AuthState) {
        guard newState != state else { return }
        state = newState
        for subscriber in subscribers {
            subscriber.continuation.yield(newState)
        }
    }
}
