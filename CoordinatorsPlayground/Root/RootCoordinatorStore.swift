//
//  RootCoordinatorStore.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import Foundation

@MainActor
class RootCoordinatorStore: ObservableObject, FlowCoordinator, ModalCoordinator {
    @Published private(set) var flow: Flow
    @Published private(set) var destination: Destination?
    
    private(set) var flowFeatures: [Flow: Feature] = [:]
    private(set) var destinationFeature: Feature?
    
    private let authStateService: AuthStateValueService
    private let authService: AuthTokenLoginService
    private let factory: RootCoordinatorFactory
    let router: any Router<RootStep>
    let restorer: any Restorer<RootState>
    
    init(
        flow: Flow,
        destination: Destination? = nil,
        authStateService: AuthStateProvider,
        authService: AuthTokenLoginService,
        factory: RootCoordinatorFactory,
        router: any Router<RootStep>,
        restorer: any Restorer<RootState>
    ) {
        self.authStateService = authStateService
        self.authService = authService
        self.factory = factory
        self.router = router
        self.restorer = restorer
        self.flow = flow
        self.destination = destination
        
        if let destination {
            makeFeature(for: destination)
        }
        makeFeature(for: flow)
        
        // MARK: - abstract with makeFeature(for flow:)
        router.register(routable: self)
        restorer.register(restorable: self)
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
    
    private func makeFeature(for flow: Flow) {
        switch flow {
        case .tabs:
            let mainTabsCoordinator = factory.makeMainTabsCoordinator(
                onAccountButtonTapped: { [weak self] in
                    self?.present(destination: .sheet(.account))
                },
                onLoginButtonTapped: { [weak self] in
                    self?.present(destination: .sheet(.auth))
                }
            )
            
            flowFeatures[flow] = mainTabsCoordinator
        }
    }
    
    private func makeFeature(for destination: Destination) {
        switch destination {
        case .sheet(let sheet):
            switch sheet {
            case .auth:
                let feature = factory.makeAuthCoordinator(onFinished: { [weak self] in
                    self?.present(destination: .sheet(.account))
                })
                destinationFeature = feature
            case .account:
                let feature = factory.makeAccountCoordinator(onFinished: { [weak self] in
                    self?.dismiss()
                })
                destinationFeature = feature
            }
        case .fullscreenCover(let fullscreenCover):
            switch fullscreenCover {
            case .onboarding:
                let feature = factory.makeOnboardingCoordinator(onFinished: { [weak self] in
                    self?.dismiss()
                })
                destinationFeature = feature
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

extension RootCoordinatorStore {
    enum Flow: Hashable, Codable {
        case tabs
    }
    
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
        return .init(destination: destination, flow: flow)
    }
    
    func restore(state: RootState) async {
        guard let destination = state.destination else { return }
        present(destination: destination)
    }
}

struct RootState: Codable {
    let destination: RootCoordinatorStore.Destination?
    let flow: RootCoordinatorStore.Flow
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
