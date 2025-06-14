//
//  SearchCoordinatorStore.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import Foundation

class SearchCoordinatorStore: ObservableObject, TabsCoordinator {
    @Published private(set) var tab: Tab
    @Published private(set) var authState: AuthState?
    
    private(set) var tabFeatures: [Tab : Feature] = [:]
    
    var onAccountButtonTapped: () -> Void = unimplemented()
    var onLoginButtonTapped: () -> Void = unimplemented()
    
    private let authStateService: AuthStateStreamService
    let router: any Router<SearchStep>
    
    init(tab: Tab = .imageFeed, authStateService: AuthStateStreamService, router: any Router<SearchStep>) {
        self.tab = tab
        self.authStateService = authStateService
        self.router = router
        
        router.register(routable: self)
    }
    
    func handleTabChanged(_ tab: Tab) {
        self.tab = tab
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
    
    private func change(tab: Tab) {
        self.tab = tab
    }
}

extension SearchCoordinatorStore {
    enum Tab: Codable, Hashable {
        case imageFeed
        case videoFeed
    }
}

extension SearchCoordinatorStore: Routable {
    func handle(step: SearchStep) async {
        switch step {
        case .change(let tab):
            switch tab {
            case .imageFeed:
                change(tab: .imageFeed)
            case .videoFeed:
                change(tab: .videoFeed)
            }
        }
    }
}

enum SearchStep: Decodable {
    enum Tab: Decodable {
        case imageFeed
        case videoFeed
    }
    
    case change(tab: Tab)
}
