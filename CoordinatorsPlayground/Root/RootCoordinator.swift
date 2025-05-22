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
            .sheet(item: .init(get: { store.sheet }, set: { store.handleSheetChanged($0) })) { sheet in
                switch sheet {
                case .auth:
                    makeView(for: .sheet(sheet), with: AuthCoordinatorStore.self, content: AuthCoordinator.init)
                case .account:
                    makeView(for: .sheet(sheet), with: AccountCoordinatorStore.self, content: AccountCoordinator.init)
                }
            }
            .fullScreenCover(item: .init(get: { store.fullscreenCover }, set: { store.handleFullscreenCoverChanged($0) })) { destination in
                switch destination {
                case .onboarding:
                    makeView(for: .fullscreenCover(.onboarding), with: OnboardingCoordinatorStore.self, content: OnboardingCoordinator.init)
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
class RootCoordinatorStore: ObservableObject {
    enum Destination: Identifiable, Hashable {
        enum Sheet: Identifiable {
            case auth
            case account
            
            var id: AnyHashable { self }
        }
        
        enum FullscreenCover: Identifiable {
            case onboarding
            
            var id: AnyHashable { self }
        }
        case sheet(Sheet)
        case fullscreenCover(FullscreenCover)
        
        var id: AnyHashable { self }
        
        var sheet: Sheet? {
            guard case .sheet(let sheet) = self else { return nil }
            return sheet
        }
        
        var fullscreenCover: FullscreenCover? {
            guard case .fullscreenCover(let fullscreenCover) = self else { return nil }
            return fullscreenCover
        }
    }
    
    @Published private var destination: Destination?
    
    var sheet: Destination.Sheet? {
        destination?.sheet
    }
    
    var fullscreenCover: Destination.FullscreenCover? {
        destination?.fullscreenCover
    }
    
    var onUnhandledRoute: (Route) async -> Bool = unimplemented(return: false)
    
    let tabsCoordinatorStore: TabsCoordinatorStore
    private var destinationStore: AnyObject?
    
    private let authStateStore: AuthStateStore
    
    init(authStateStore: AuthStateStore) {
        self.authStateStore = authStateStore
    
        tabsCoordinatorStore = TabsCoordinatorStore(selectedTab: .second, authStateStore: authStateStore)
        tabsCoordinatorStore.onAccountButtonTapped = { [weak self] in
            self?.present(destination: .sheet(.account))
        }
        tabsCoordinatorStore.onLoginButtonTapped = { [weak self] in
            self?.present(destination: .sheet(.auth))
        }
        tabsCoordinatorStore.onUnhandledRoute = { [weak self] route in
            guard let self else { return false }
            return await self.onUnhandledRoute(route)
        }
        
        // Implements its own closure since this is the last stop for handling routes :)
        onUnhandledRoute = { [weak self] route in
            guard let self else { return false }
            return await self.handle(route: route)
        }
        
//        makeStore(for: .fullscreenCover(.onboarding))
//        self.destination = .fullscreenCover(.onboarding)
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
    
    func store<T>(for destination: Destination, of type: T.Type) -> T? {
        destinationStore as? T
    }
    
    func handleSheetChanged(_ sheet: Destination.Sheet?) {
        if let sheet {
            destination = .sheet(sheet)
        } else {
            destinationStore = nil
            destination = nil
        }
    }
    
    func handleFullscreenCoverChanged(_ fullscreenCover: Destination.FullscreenCover?) {
        if let fullscreenCover {
            destination = .fullscreenCover(fullscreenCover)
        } else {
            destinationStore = nil
            destination = nil
        }
    }
    
    private func makeStore(for destination: Destination) {
        switch destination {
        case .sheet(let sheet):
            switch sheet {
            case .auth:
                let store = AuthCoordinatorStore(authStateStore: authStateStore)
                store.onFinished = { [weak self] in
                    self?.present(destination: .sheet(.account))
                }
                destinationStore = store
            case .account:
                let store = AccountCoordinatorStore(authStateStore: authStateStore)
                store.onFinished = { [weak self] in
                    self?.dismiss()
                }
                destinationStore = store
            }
        case .fullscreenCover(let fullscreenCover):
            switch fullscreenCover {
            case .onboarding:
                let store = OnboardingCoordinatorStore()
                store.onFinished = { [weak self] in
                    self?.dismiss()
                }
                destinationStore = store
            }
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
    
    private func login() async {
        await authStateStore.setState(.loginInProgress)
        try? await Task.sleep(for: .seconds(2))
        await authStateStore.setState(.loggedIn)
    }
    
    private func handleAccountRoute(with authToken: String?) async {
        let authState = await authStateStore.currentValue
        switch authState {
        case .loggedIn:
            present(destination: .sheet(.account))
        case .loginInProgress:
            break
        case .loggedOut:
            if authToken != nil {
                await login()
                present(destination: .sheet(.account))
            } else {
                present(destination: .sheet(.auth))
            }
        }
    }
}

extension RootCoordinatorStore: Router {
    func handle(route: Route) async -> Bool {
        let didHandleStep = await handle(step: route.step)
        
        guard didHandleStep else {
            return false
        }
        
        let routers = [tabsCoordinatorStore, destinationStore]
            .compactMap { $0 as? Router }
        
        for route in route.children {
            for router in routers {
                if await router.handle(route: route) {
                    break
                }
            }
        }
        
        return true
    }
    
    private func handle(step: Route.Step) async -> Bool {
        switch step {
        case .present(let destination):
            switch destination {
            case .login:
                present(destination: .sheet(.auth))
                return true
            case .account(let authToken):
                await handleAccountRoute(with: authToken)
                return true
            default:
                return false
            }
        case .flow:
            // If tabs should get deinited for some other flow
            // For example if Auth Screen was not a global modal, but a separate flow from Tabs it would be handeled here
            // Just propagate for now to fulfill the whole app flow without skips
            return true
        case .tab, .push:
            return false
        }
    }
}

@MainActor
protocol Router {
    var onUnhandledRoute: (Route) async -> Bool { get }
    func handle(route: Route) async -> Bool
}

extension Router {
    func handle(childRoutes: [Route], using childRouters: [Router]) async -> Bool {
        for route in childRoutes {
            var didHandleStep = false
            
            for router in childRouters {
                if await router.handle(route: route) {
                    didHandleStep = true
                    break
                }
            }
            
            // If none of the child routers handled this child route
            if !didHandleStep {
                return await onUnhandledRoute(route)
            }
        }
        
        return true
    }
}

enum AuthState {
    case loggedIn
    case loginInProgress
    case loggedOut
}

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

func unimplemented<T, U>(
  _ name: String = #function,
  return defaultValue: U
) -> (T) async -> U {
    return { _ in
        assertionFailure("⚠️ Unimplemented closure: \(name)")
        return defaultValue
    }
}

//func unimplemented<T>(
//  _ name: String = #function
//) -> (T) async -> Void {
//    return { _ in
//        assertionFailure("⚠️ Unimplemented closure: \(name)")
//    }
//}

func unimplemented<T>(
  _ name: String = #function
) -> (T) -> Void {
    return { _ in
        assertionFailure("⚠️ Unimplemented closure: \(name)")
    }
}

func unimplemented(
  _ name: String = #function
) -> () -> Void {
    return {
        assertionFailure("⚠️ Unimplemented closure: \(name)")
    }
}
