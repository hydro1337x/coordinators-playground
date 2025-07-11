//
//  AuthCoordinatorFactoryTests.swift
//  CoordinatorsPlaygroundTests
//
//  Created by Benjamin Macanovic on 25.05.2025..
//

import Testing
import SwiftUI
@testable import CoordinatorsPlayground

@MainActor
struct AuthCoordinatorFactoryTests {
    let sut = DefaultAccountCoordinatorFactory()
    
    @Test func test_makeAccountDetails() async throws {
        let feature = sut.makeDetailsScreen()
        
        #expect(feature.cast(to: AccountDetailsStore.self) != nil)
        #expect(String(describing: feature.underlyingView).contains("AccountDetailsScreen"))
    }

}
