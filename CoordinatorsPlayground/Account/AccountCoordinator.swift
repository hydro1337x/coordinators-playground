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
                    view(for: path)
                }
            }
            .navigationTitle("Account")
        }
    }
    
    @ViewBuilder
    func view(for path: AccountCoordinatorStore.Path) -> some View {
        if let view = store.pathFeatures[path] {
            view
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
    private(set) var pathFeatures: [Path: Feature] = [:]
    
    var onFinished: () -> Void = unimplemented()
    var onUnhandledRoute: (Route) async -> Bool = unimplemented(return: false)
    
    private let logoutService: LogoutService
    private let factory: AccountCoordinatorFactory
    
    init(logoutService: LogoutService, factory: AccountCoordinatorFactory) {
        self.logoutService = logoutService
        self.factory = factory
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
    
    func handlePathChanged(_ newPath: [Path]) {
        if newPath.count < path.count {
            let poppedPath = Array(path.suffix(from: newPath.count))
            poppedPath.forEach { pathFeatures[$0] = nil }
        }
        
        path = newPath
    }
    // Remove cache -> make StateObject and just return created AnyView when Coordinator destination requests it
    private func makeView(for path: Path) {
        guard pathFeatures[path] == nil else { return }
        
        switch path {
        case .details:
            pathFeatures[path] = factory.makeAccountDetails()
        }
    }
    
    func handleLogoutButtonTapped() async {
        await logoutService.logout()
        
        onFinished()
    }
    
    private func push(path: Path) {
        makeView(for: path)
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
