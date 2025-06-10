//
//  SearchCoordinatorStore.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import Foundation

class SearchCoordinatorStore: ObservableObject, TabNavigationObservable {
    @Published private(set) var tab: Tab
    @Published private(set) var authState: AuthState?
    
    private(set) var tabFeatures: [Tab : Feature] = [:]
    
    var onAccountButtonTapped: () -> Void = unimplemented()
    var onLoginButtonTapped: () -> Void = unimplemented()
    
    private let authStateService: AuthStateStreamService
    
    init(tab: Tab = .imageFeed, authStateService: AuthStateStreamService) {
        self.tab = tab
        self.authStateService = authStateService
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
}

extension SearchCoordinatorStore {
    enum Tab: Codable, Hashable {
        case imageFeed
        case videoFeed
    }
}
