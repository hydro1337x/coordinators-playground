//
//  RootCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import SwiftUI

struct RootCoordinator: View {
    @ObservedObject var store: RootCoordinatorStore
    var makeFloatingStack: () -> AnyView
    
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
                .overlay(content: makeFloatingStack)
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
    
    private(set) var tabsCoordinator: Feature?
    private(set) var destinationFeature: Feature?
    
    private let authStateService: AuthStateValueService
    private let authService: AuthTokenLoginService
    private let factory: RootCoordinatorFactory
    let router: any Router<RootStep>
    let restorer: any Restorer<RootState>
    
    init(authStateService: AuthStateProvider, authService: AuthTokenLoginService, factory: RootCoordinatorFactory, router: any Router<RootStep>, restorer: any Restorer<RootState>) {
        self.authStateService = authStateService
        self.authService = authService
        self.factory = factory
        self.router = router
        self.restorer = restorer
        let tabsCoordinator = factory.makeTabsCoordinator(
            onAccountButtonTapped: { [weak self] in
                self?.present(destination: .sheet(.account))
            },
            onLoginButtonTapped: { [weak self] in
                self?.present(destination: .sheet(.auth))
            }
        )
        self.tabsCoordinator = tabsCoordinator
        
        router.setup(using: self, childRoutables: { [weak self] in
            guard let self else { return [] }
            return [self.tabsCoordinator, self.destinationFeature]
                .compactMap { $0?.cast() }
        })
        
        restorer.setup(using: self, childRestorables: { [weak self] in
            guard let self else { return [] }
            return [self.destinationFeature, self.tabsCoordinator]
                .compactMap { $0?.cast() }
        })
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

extension RootCoordinatorStore: Routable {
    func handle(step: RootStep) async {
        switch step {
        case .present(let destination):
            switch destination {
            case .login:
                present(destination: .sheet(.auth))
            case .account(let authToken):
                await handleAccountRoute(with: authToken)
            }
        case .transition:
            // If tabs should get deinited for some other flow
            // For example if Auth Screen was not a global modal, but a separate flow from Tabs it would be handeled here
            // Just propagate for now to fulfill the whole app flow without skips
            break
        }
    }
}

extension RootCoordinatorStore: Restorable {
    func captureState() async -> RootState {
        return .init(destination: destination)
    }
    
    func restore(state: RootState) async {
        guard let destination = state.destination else { return }
        present(destination: destination)
    }
}

struct RootState: Codable {
    let destination: RootCoordinatorStore.Destination?
}

enum RootStep: Decodable {
    enum Destination: Decodable {
        case login
        case account(authToken: String?)
    }

    enum Flow: Decodable {
        case tabs
    }

    case present(destination: Destination)
    case transition(flow: Flow)
}
