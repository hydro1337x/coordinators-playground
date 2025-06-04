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
                VStack {
                    Button("Show Details") {
                        Task { await store.handleShowDetailsButtonTapped() }
                    }
                    Text("Theme")
                    HStack {
                        Button("Light") {
                            Task {  await store.handleLightThemeButtonTapped() }
                        }
                        
                        Button("Dark") {
                            Task { await store.handleDarkThemeButtonTapped() }
                        }
                    }
                }
                Spacer()
                Button("Logout") {
                    Task { await store.handleLogoutButtonTapped() }
                }
            }
            .navigationDestination(for: AccountCoordinatorStore.Path.self) { path in
                switch path {
                case .details:
                    makeFeature(for: path)
                }
            }
            .navigationTitle("Account")
        }
    }
    
    @ViewBuilder
    func makeFeature(for path: AccountCoordinatorStore.Path) -> some View {
        if let view = store.pathFeatures[path] {
            view
        } else {
            Text("Something went wrong")
        }
    }
}

@MainActor
class AccountCoordinatorStore: ObservableObject {
    enum Path: Codable {
        case details
    }
    
    @Published private(set) var path: [Path] = []
    private(set) var pathFeatures: [Path: Feature] = [:]
    
    var onFinished: () -> Void = unimplemented()
    
    private let logoutService: LogoutService
    private let themeService: SetThemeService
    private let factory: AccountCoordinatorFactory
    let router: any Router<AccountStep>
    let restorer: any Restorer<AccountState>
    
    init(logoutService: LogoutService, themeService: SetThemeService, factory: AccountCoordinatorFactory, router: any Router<AccountStep>, restorer: any Restorer<AccountState>) {
        self.logoutService = logoutService
        self.themeService = themeService
        self.factory = factory
        self.router = router
        self.restorer = restorer
        
        router.setup(using: self, childRoutables: {
            []
        })
        
        restorer.setup(using: self, childRestorables: {
            []
        })
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
    
    func handleShowDetailsButtonTapped() {
        push(path: .details)
    }
    
    private func makeFeature(for path: Path) {
        guard pathFeatures[path] == nil else { return }
        
        switch path {
        case .details:
            pathFeatures[path] = factory.makeAccountDetails()
        }
    }
    
    func handleLightThemeButtonTapped() async {
        await themeService.set(theme: .light)
    }
    
    func handleDarkThemeButtonTapped() async {
        await themeService.set(theme: .dark)
    }
    
    func handleLogoutButtonTapped() async {
        await logoutService.logout()
        
        onFinished()
    }
    
    private func push(path: Path) {
        makeFeature(for: path)
        self.path.append(path)
    }
}

extension AccountCoordinatorStore: Routable {
    func handle(step: AccountStep) async {
        switch step {
        case .push(let path):
            switch path {
            case .accountDetails:
                push(path: .details)
            }
        }
    }
}

extension AccountCoordinatorStore: Restorable {
    func captureState() async -> AccountState {
        return .init(path: path)
    }
    
    func restore(state: AccountState) async {
        state.path.forEach { makeFeature(for: $0) }
        self.path = state.path
    }
}

struct AccountState: Codable {
    let path: [AccountCoordinatorStore.Path]
}

enum AccountStep: Decodable {
    enum Path: Decodable {
        case accountDetails
    }

    case push(path: Path)
}
