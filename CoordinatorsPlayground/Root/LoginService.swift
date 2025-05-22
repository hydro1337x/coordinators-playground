//
//  LoginService.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 22.05.2025..
//

import Foundation

protocol AuthTokenLoginService: Sendable {
    func login(authToken: String?) async throws
}

struct LoginService: AuthTokenLoginService {
    let authStateProvider: AuthStateProvider
    
    func login(authToken: String?) async throws {
        guard let authToken else { throw URLError(.badServerResponse) }
        
        await authStateProvider.setState(.loginInProgress)
        try await Task.sleep(for: .seconds(2))
        await authStateProvider.setState(.loggedIn)
    }
}
