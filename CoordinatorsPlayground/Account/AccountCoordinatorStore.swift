//
//  AccountCoordinatorStore.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import Foundation

@MainActor
class AccountCoordinatorStore: ObservableObject, StackCoordinator, ModalCoordinator {
    @Published private(set) var destination: Destination?
    @Published private(set) var path: [Path] = []
    
    private(set) var destinationFeature: Feature?
    private(set) var rootFeature: Feature?
    private(set) var pathFeatures: [Path: Feature] = [:]
    
    var onFinished: () -> Void = unimplemented()
    
    private let factory: AccountCoordinatorFactory
    let router: any Router<AccountStep>
    let restorer: any Restorer<AccountState>
    
    init(factory: AccountCoordinatorFactory, router: any Router<AccountStep>, restorer: any Restorer<AccountState>) {
        self.factory = factory
        self.router = router
        self.restorer = restorer
        
        rootFeature = factory.makeAccountRoot(
            onDetailsButtonTapped: { [weak self] in
                self?.push(path: .details)
            },
            onHelpButtonTapped: { [weak self] in
                self?.present(destination: .sheet(.help))
            },
            onLogoutFinished: { [weak self] in
                self?.onFinished()
            }
        )
        
        router.register(routable: self)
        
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

extension AccountCoordinatorStore {
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
