//
//  DefaultRootCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 25.05.2025..
//

import Foundation
import SwiftUI

@MainActor
protocol RootCoordinatorFactory {
    func makeAuthCoordinator(onFinished: @escaping () -> Void) -> Feature
    func makeAccountCoordinator(onFinished: @escaping () -> Void) -> Feature
    func makeOnboardingCoordinator(onFinished: @escaping () -> Void) -> Feature
    func makeMainTabsCoordinator(onAccountButtonTapped: @escaping () -> Void, onLoginButtonTapped: @escaping () -> Void) -> Feature
    func makeSpecialFlowCoordinator(onMainFlowButtonTapped: @escaping () -> Void) -> Feature
}
