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
    let service: SetAuthStateService
    
    func login(authToken: String?) async throws {
        guard authToken != nil else { throw URLError(.badServerResponse) }
        
        await service.setState(.loginInProgress)
        try await Task.sleep(for: .seconds(2))
        await service.setState(.loggedIn)
    }
}
