//
//  DefaultAccountCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 23.05.2025..
//

import SwiftUI

@MainActor
protocol AccountCoordinatorFactory {
    func makeRootScreen(
        onDetailsButtonTapped: @escaping () -> Void,
        onHelpButtonTapped: @escaping () -> Void,
        onLogoutFinished: @escaping () -> Void
    ) -> Feature
    func makeDetailsScreen() -> Feature
    func makeHelpScreen(onDismiss: @escaping () -> Void) -> Feature
}
