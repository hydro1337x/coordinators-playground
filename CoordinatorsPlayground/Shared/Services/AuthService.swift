//
//  AuthService.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 17.06.2025..
//

import Foundation

protocol AuthTokenLoginService: Sendable {
    func login(authToken: String?) async throws
}

protocol LogoutService: Sendable {
    func logout() async
}
