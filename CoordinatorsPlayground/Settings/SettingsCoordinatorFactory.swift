//
//  SettingsCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 14.06.2025..
//

import Foundation

@MainActor
protocol SettingsCoordinatorFactory {
    func makeRootFeature() -> Feature
}
