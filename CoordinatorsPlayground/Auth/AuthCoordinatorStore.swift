//
//  AuthCoordinatorStore.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import Foundation

@MainActor
class AuthCoordinatorStore: ObservableObject {
    @Published var isLoading = false
    
    var onFinished: () -> Void = unimplemented()
    let authService: AuthTokenLoginService
    let authStateService: AuthStateStreamService
    
    init(authStateService: AuthStateStreamService, authService: AuthTokenLoginService) {
        self.authStateService = authStateService
        self.authService = authService
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
    
    func bindObservers() async {
        for await state in await authStateService.values {
            switch state {
            case .loginInProgress:
                isLoading = true
            case .loggedIn, .loggedOut:
                isLoading = false
            }
        }
    }
    
    func handleLoginTapped() async {
        try? await authService.login(authToken: "")
        
        onFinished()
    }
}
