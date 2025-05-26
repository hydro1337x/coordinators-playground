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
        if let tabsCoordinator = store.tabsCoordinator {
            tabsCoordinator
                .sheet(item: .init(get: { store.sheet }, set: { store.handleSheetChanged($0) })) { sheet in
                    switch sheet {
                    case .auth:
                        destinationFeature()
                    case .account:
                        destinationFeature()
                    }
                }
                .fullScreenCover(item: .init(get: { store.fullscreenCover }, set: { store.handleFullscreenCoverChanged($0) })) { destination in
                    switch destination {
                    case .onboarding:
                        destinationFeature()
                    }
                }
        } else {
            Text("Something went wrong")
        }
    }
    
    @ViewBuilder
    func destinationFeature() -> some View {
        if let view = store.destinationFeature {
            view
        } else {
            Text("Something went wrong")
        }
    }
}

@MainActor
class RootCoordinatorStore: ObservableObject {
    enum Destination: Identifiable, Hashable, Codable {
        enum Sheet: Identifiable, Codable {
            case auth
            case account
            
            var id: AnyHashable { self }
        }
        
        enum FullscreenCover: Identifiable, Codable {
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
    
    var sheet: Destination.Sheet? { destination?.sheet }
    var fullscreenCover: Destination.FullscreenCover? { destination?.fullscreenCover }
    
    var onUnhandledRoute: (Route) async -> Bool = unimplemented(return: false)
    
    private(set) var tabsCoordinator: Feature?
    private(set) var destinationFeature: Feature?
    
    private let authStateService: AuthStateValueService
    private let authService: AuthTokenLoginService
    private let factory: RootCoordinatorFactory
    
    init(authStateService: AuthStateProvider, authService: AuthTokenLoginService, factory: RootCoordinatorFactory) {
        self.authStateService = authStateService
        self.authService = authService
        self.factory = factory
        let tabsCoordinator = factory.makeTabsCoordinator(
            onAccountButtonTapped: { [weak self] in
                self?.present(destination: .sheet(.account))
            },
            onLoginButtonTapped: { [weak self] in
                self?.present(destination: .sheet(.auth))
            },
            onUnhandledRoute: { [weak self] route in
                guard let self else { return false }
                return await self.onUnhandledRoute(route)
            }
        )
        self.tabsCoordinator = tabsCoordinator
        
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
    
    func handleSheetChanged(_ sheet: Destination.Sheet?) {
        if let sheet {
            destination = .sheet(sheet)
        } else {
            destinationFeature = nil
            destination = nil
        }
    }
    
    func handleFullscreenCoverChanged(_ fullscreenCover: Destination.FullscreenCover?) {
        if let fullscreenCover {
            destination = .fullscreenCover(fullscreenCover)
        } else {
            destinationFeature = nil
            destination = nil
        }
    }
    
    private func makeFeature(for destination: Destination) {
        switch destination {
        case .sheet(let sheet):
            switch sheet {
            case .auth:
                let view = factory.makeAuthCoordinator(onFinished: { [weak self] in
                    self?.present(destination: .sheet(.account))
                })
                destinationFeature = view
            case .account:
                let view = factory.makeAccountCoordinator(onFinished: { [weak self] in
                    self?.dismiss()
                })
                destinationFeature = view
            }
        case .fullscreenCover(let fullscreenCover):
            switch fullscreenCover {
            case .onboarding:
                let view = factory.makeOnboardingCoordinator(onFinished: { [weak self] in
                    self?.dismiss()
                })
                destinationFeature = view
            }
        }
    }
    
    private func present(destination: Destination) {
        destinationFeature = nil
        makeFeature(for: destination)
        self.destination = destination
    }
    
    private func dismiss() {
        destinationFeature = nil
        self.destination = nil
    }
    
    private func handleAccountRoute(with authToken: String?) async {
        let authState = await authStateService.currentValue
        switch authState {
        case .loggedIn:
            present(destination: .sheet(.account))
        case .loginInProgress:
            break
        case .loggedOut:
            do {
                try await authService.login(authToken: authToken)
                present(destination: .sheet(.account))
            } catch {
                present(destination: .sheet(.auth))
            }
        }
    }
}

extension RootCoordinatorStore: Router {
    var childRouters: [any Router] {
        [tabsCoordinator, destinationFeature]
            .compactMap { $0?.as(type: Router.self) }
    }
    
    // Has custom handle(route:) since it must not call onUnhandledRoute since it's the root
    func handle(route: Route) async -> Bool {
        let didHandleStep = await handle(step: route.step)
        
        guard didHandleStep else {
            return false
        }
        
        for route in route.children {
            for router in childRouters {
                if await router.handle(route: route) {
                    break
                }
            }
        }
        
        return true
    }
    
    func handle(step: Data) async -> Bool {
        do {
            let step = try JSONDecoder().decode(RootStep.self, from: step)
            return await handle(step: step)
        } catch {
            return false
        }
    }
    
    private func handle(step: RootStep) async -> Bool {
        switch step {
        case .present(let destination):
            switch destination {
            case .login:
                present(destination: .sheet(.auth))
                return true
            case .account(let authToken):
                await handleAccountRoute(with: authToken)
                return true
            }
        case .flow:
            // If tabs should get deinited for some other flow
            // For example if Auth Screen was not a global modal, but a separate flow from Tabs it would be handeled here
            // Just propagate for now to fulfill the whole app flow without skips
            return true
        }
    }
}

struct RootState: Codable {
    let destination: RootCoordinatorStore.Destination?
}

struct RestorableState: Codable {
    let step: Data
    let children: [Data]
}

extension RootCoordinatorStore: StateRestoring {
    func saveState() throws -> [Data] {
        let children = [tabsCoordinator].compactMap { $0?.as(type: StateRestoring.self) }
        var data = try children.flatMap { try $0.saveState() }
        let state = RootState(destination: destination)
        data.insert(try encode(state), at: 0)
        return data
    }
    
    func restoreState(from data: [Data]) throws {
        guard let first = data.first else { return }
        let data = Array(data.dropFirst())
        
        let state = try decode(first, as: RootState.self)
        
        if let destination = state.destination {
            makeFeature(for: destination)
            self.destination = destination
        }
        
        let children = [tabsCoordinator].compactMap { $0?.as(type: StateRestoring.self) }
        try children.forEach { try $0.restoreState(from: data) }
    }
}

enum RootStep: Decodable {
    enum Destination: Decodable {
        case login
        case account(authToken: String?)

        enum CodingKeys: String, CodingKey {
            case value
            case authToken
        }

        init(from decoder: Decoder) throws {
            // Handle simple single-value cases (e.g., "login")
            if let container = try? decoder.singleValueContainer(),
               let string = try? container.decode(String.self),
               string == "login" {
                self = .login
                return
            }

            // Handle object cases (e.g., { "value": "account", "authToken": "..." })
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let value = try container.decode(String.self, forKey: .value)

            switch value {
            case "account":
                let token = try container.decodeIfPresent(String.self, forKey: .authToken)
                self = .account(authToken: token)
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .value,
                    in: container,
                    debugDescription: "Unknown Destination value: \(value)"
                )
            }
        }
    }

    enum Flow: Decodable {
        case tabs

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            switch string {
            case "tabs": self = .tabs
            default:
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown flow: \(string)")
            }
        }
    }

    case present(Destination)
    case flow(Flow)

    enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    enum StepType: String, Decodable {
        case present
        case flow
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StepType.self, forKey: .type)

        switch type {
        case .present:
            let destination = try container.decode(Destination.self, forKey: .value)
            self = .present(destination)
        case .flow:
            let flow = try container.decode(Flow.self, forKey: .value)
            self = .flow(flow)
        }
    }
}
