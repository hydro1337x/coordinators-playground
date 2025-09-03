//
//  AuthStateService.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 17.06.2025..
//

import Foundation

enum AuthState {
    case loggedIn
    case loginInProgress
    case loggedOut
}

protocol AuthStateValueService: Sendable {
    var currentValue: AuthState { get async }
}

protocol AuthStateStreamService: Sendable {
    var values: AsyncStream<AuthState> { get async }
}

protocol SetAuthStateService: Sendable {
    func setState(_ newState: AuthState) async
}
