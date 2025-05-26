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
            makeRootFeature()
                .navigationDestination(for: HomeCoordinatorStore.Path.self) { path in
                    makeFeature(for: path)
                        .toolbar(content: toolbarButton)
                }
                .navigationTitle("Home Screen")
                .toolbar(content: toolbarButton)
        }
        .sheet(
            item: .init(get: { store.destination }, set: { store.handleDestinationChanged($0) }),
            content: { destination in
                switch destination {
                case .screenB:
                    makeDestinatonFeature()
                }
            }
        )
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
    func makeRootFeature() -> some View {
        if let view = store.rootFeature {
            view
        } else {
            Text("Something went wrong")
        }
    }
    
    @ViewBuilder
    func makeDestinatonFeature() -> some View {
        if let view = store.destinationFeature {
            view
        } else {
            Text("Something went wrong")
        }
    }
    
    @ViewBuilder
    func makeFeature(
        for path: HomeCoordinatorStore.Path
    ) -> some View {
        if let view = store.pathFeatures[path] {
            view
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
    
    private(set) var destinationFeature: Feature?
    private(set) var pathFeatures: [Path: Feature] = [:]
    private(set) var rootFeature: Feature?
    
    var onAccountButtonTapped: () -> Void = unimplemented()
    var onLoginButtonTapped: () -> Void = unimplemented()
    var onUnhandledRoute: (Route) async -> Bool = unimplemented(return: false)
    
    private let authStateService: AuthStateStreamService
    private let factory: HomeCoordinatorFactory
    
    init(path: [Path], authStateService: AuthStateStreamService, factory: HomeCoordinatorFactory) {
        self.authStateService = authStateService
        self.factory = factory
        self.rootFeature = factory.makeHomeScreen(onButtonTap: { [weak self] in
            self?.push(path: .screenA)
        })
        path.forEach { makeFeature(for:$0) }
        
        self.path = path
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
    
    func handleDestinationChanged(_ destination: Destination?) {
        if let destination {
            self.destination = destination
        } else {
            destinationFeature = nil
            self.destination = nil
        }
    }
    
    func handlePathChanged(_ newPath: [Path]) {
        if newPath.count < path.count {
            let poppedPath = Array(path.suffix(from: newPath.count))
            poppedPath.forEach { pathFeatures[$0] = nil }
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
        for await state in await authStateService.values {
            authState = state
        }
    }
    
    func makeFeature(for destination: Destination) {
        switch destination {
        case .screenB(let id):
            let view = factory.makeScreenB(
                id: id,
                onPushClone: { [weak self] nextId in
                    self?.push(path: .screenB(id: nextId))
                }, onPushNext: { [weak self] in
                    self?.push(path: .screenC)
                }
            )
            
            destinationFeature = view
        }
    }
    
    private func makeFeature(for path: Path) {
        guard pathFeatures[path] == nil else { return }
        
        switch path {
        case .screenA:
            let view = factory.makeScreenA(onButtonTap: { [weak self] in
                self?.push(path: .screenB(id: 1))
            })
            pathFeatures[path] = view
        case .screenB(let id):
            let view = factory.makeScreenB(
                id: id,
                onPushClone: { [weak self] nextId in
                    self?.push(path: .screenB(id: nextId))
                },
                onPushNext: { [weak self] in
                    self?.push(path: .screenC)
                }
            )
            
            pathFeatures[path] = view
        case .screenC:
            let view = factory.makeScreenC(
                onBackButtonTapped: { [weak self] in
                    self?.pop()
                }
            )
            
            pathFeatures[path] = view
        }
    }
    
    private func present(destination: Destination) {
        switch destination {
        case .screenB:
            makeFeature(for: destination)
            self.destination = destination
        }
    }
    
    private func push(path: Path) {
        makeFeature(for: path)
        self.path.append(path)
    }
    
    private func pop() {
        guard !path.isEmpty else { return }
        
        let lastPath = path.removeLast()
        
        pathFeatures[lastPath] = nil
    }
}

extension HomeCoordinatorStore: Router {
    var childRouters: [any Router] {
        [
            [destinationFeature?.as(type: Router.self)],
            pathFeatures.values.map { $0.as(type: Router.self) }
        ]
        .flatMap { $0 }
        .compactMap { $0 }
    }
    
    func handle(step: Route.Step) async -> Bool {
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

