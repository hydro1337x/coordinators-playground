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
                        makeView(for: .sheet(sheet))
                    case .account:
                        makeView(for: .sheet(sheet))
                    }
                }
                .fullScreenCover(item: .init(get: { store.fullscreenCover }, set: { store.handleFullscreenCoverChanged($0) })) { destination in
                    switch destination {
                    case .onboarding:
                        makeView(for: .fullscreenCover(.onboarding))
                    }
                }
        } else {
            Text("Something went wrong")
        }
    }
    
    @ViewBuilder
    func makeView(
        for destination: RootCoordinatorStore.Destination
    ) -> some View {
        if let view = store.destinationView {
            view
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
    
    private(set) var tabsCoordinator: Feature?
    private(set) var destinationView: Feature?
    
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
            destinationView = nil
            destination = nil
        }
    }
    
    func handleFullscreenCoverChanged(_ fullscreenCover: Destination.FullscreenCover?) {
        if let fullscreenCover {
            destination = .fullscreenCover(fullscreenCover)
        } else {
            destinationView = nil
            destination = nil
        }
    }
    
    private func makeStore(for destination: Destination) {
        switch destination {
        case .sheet(let sheet):
            switch sheet {
            case .auth:
                let view = factory.makeAuthCoordinator(onFinished: { [weak self] in
                    self?.present(destination: .sheet(.account))
                })
                destinationView = view
            case .account:
                let view = factory.makeAccountCoordinator(onFinished: { [weak self] in
                    self?.dismiss()
                })
                destinationView = view
            }
        case .fullscreenCover(let fullscreenCover):
            switch fullscreenCover {
            case .onboarding:
                let view = factory.makeOnboardingCoordinator(onFinished: { [weak self] in
                    self?.dismiss()
                })
                destinationView = view
            }
        }
    }
    
    private func present(destination: Destination) {
        destinationView = nil
        makeStore(for: destination)
        self.destination = destination
    }
    
    private func dismiss() {
        destinationView = nil
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
    func handle(route: Route) async -> Bool {
        let didHandleStep = await handle(step: route.step)
        
        guard didHandleStep else {
            return false
        }
        
        let routers = [tabsCoordinator, destinationView]
            .compactMap { $0?.asRouter() }
        
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
