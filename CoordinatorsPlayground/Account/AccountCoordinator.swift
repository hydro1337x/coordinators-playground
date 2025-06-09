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
        NavigationStack(path: .binding(state: { store.path }, with: store.handlePathChanged)) {
            VStack {
                Text("User Bob Account")
                VStack {
                    Button("Push Details") {
                        store.handleShowDetailsButtonTapped()
                    }
                    Button("Present Help") {
                        store.handlePresentHelpButtonTapped()
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
        .sheet(item: .binding(
                    state: { store.destination?.sheet },
                    with: store.handleSheetChanged
                )
        ) { sheet in
            switch sheet {
            case .help:
                makeDestinatonFeature()
            }
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
    func makeFeature(for path: AccountCoordinatorStore.Path) -> some View {
        if let view = store.pathFeatures[path] {
            view
        } else {
            Text("Something went wrong")
        }
    }
}

@MainActor
class AccountCoordinatorStore: ObservableObject, StackNavigationObservable, ModalNavigationObservable {
    enum Destination: Identifiable, Hashable, Codable {
        enum Sheet: Identifiable, Hashable, Codable {
            case help
            
            var id: AnyHashable { self }
        }
        
        case sheet(Sheet)
        
        var id: AnyHashable { self }
        
        var sheet: Sheet? {
            guard case .sheet(let sheet) = self else { return nil }
            return sheet
        }
    }
    
    enum Path: Hashable, Codable {
        case details
    }
    
    @Published private(set) var destination: Destination?
    @Published private(set) var path: [Path] = []
    
    private(set) var destinationFeature: Feature?
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
    
    func handleSheetChanged(_ sheet: Destination.Sheet?) {
        if let sheet {
            destination = .sheet(sheet)
        } else {
            destinationFeature = nil
            destination = nil
        }
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
    
    func handlePresentHelpButtonTapped() {
        present(destination: .sheet(.help))
    }
    
    private func makeFeature(for destination: Destination) {
        switch destination {
        case .sheet(let sheet):
            switch sheet {
            case .help:
                let feature = factory.makeAccountHelp(onDismiss: { [weak self] in
                    self?.dismiss()
                })
                destinationFeature = feature
            }
        }
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
    
    private func present(destination: Destination) {
        destinationFeature = nil
        makeFeature(for: destination)
        self.destination = destination
    }
    
    private func dismiss() {
        destinationFeature = nil
        self.destination = nil
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
        case .present(destination: let destination):
            switch destination {
            case .help:
                present(destination: .sheet(.help))
            }
        }
    }
}

extension AccountCoordinatorStore: Restorable {
    func captureState() async -> AccountState {
        return .init(path: path, destination: destination)
    }
    
    func restore(state: AccountState) async {
        state.path.forEach { makeFeature(for: $0) }
        self.path = state.path
    }
}

struct AccountState: Codable {
    let path: [AccountCoordinatorStore.Path]
    let destination: AccountCoordinatorStore.Destination?
}

enum AccountStep: Decodable {
    enum Destination: Decodable {
        case help
    }
    
    enum Path: Decodable {
        case accountDetails
    }

    case present(destination: Destination)
    case push(path: Path)
}
