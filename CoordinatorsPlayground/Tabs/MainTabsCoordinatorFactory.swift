//
//  MainTabsCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 25.05.2025..
//

import Foundation

@MainActor
protocol MainTabsCoordinatorFactory {
    func makeHomeCoordinator(
        onAccountButtonTapped: @escaping () -> Void,
        onLoginButtonTapped: @escaping () -> Void
    ) -> Feature
    
    func makeSearchCoordinator(
        onAccountButtonTapped: @escaping () -> Void,
        onLoginButtonTapped: @escaping () -> Void
    ) -> Feature
    
    func makeSettingsCoordinator() -> Feature
}
