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
    
    func handle(step: Data) async -> Bool {
        do {
            let step = try JSONDecoder().decode(HomeStep.self, from: step)
            return await handle(step: step)
        } catch {
            return false
        }
    }
    
    private func handle(step: HomeStep) async -> Bool {
        switch step {
        case .present(let destination):
            switch destination {
            case .screenB(id: let id):
                present(destination: .screenB(id: id))
                return true
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
            }
        }
    }
}

enum HomeStep: Decodable {
    enum Destination: Decodable {
        case screenB(id: Int)

        private enum CodingKeys: String, CodingKey {
            case value, id
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let value = try container.decode(String.self, forKey: .value)

            switch value {
            case "screenB":
                let id = try container.decode(Int.self, forKey: .id)
                self = .screenB(id: id)
            default:
                throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Invalid Destination: \(value)")
            }
        }
    }

    enum Path: Decodable {
        case screenA
        case screenB(id: Int)
        case screenC

        private enum CodingKeys: String, CodingKey {
            case value, id
        }

        init(from decoder: Decoder) throws {
            // First, try as a single string value
            if let container = try? decoder.singleValueContainer(),
               let stringValue = try? container.decode(String.self) {
                switch stringValue {
                case "screenA": self = .screenA
                case "screenC": self = .screenC
                default:
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid Path value: \(stringValue)")
                }
                return
            }

            // Otherwise try decoding as a full object
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let value = try container.decode(String.self, forKey: .value)

            switch value {
            case "screenB":
                let id = try container.decode(Int.self, forKey: .id)
                self = .screenB(id: id)
            default:
                throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Invalid Path: \(value)")
            }
        }
    }

    case present(Destination)
    case push(Path)

    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    private enum StepType: String, Decodable {
        case present
        case push
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StepType.self, forKey: .type)

        switch type {
        case .present:
            let destination = try container.decode(Destination.self, forKey: .value)
            self = .present(destination)
        case .push:
            let path = try container.decode(Path.self, forKey: .value)
            self = .push(path)
        }
    }
}
