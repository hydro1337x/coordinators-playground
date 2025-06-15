//
//  SettingsCoordinatorStore.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 14.06.2025..
//

import Foundation

@MainActor
class SettingsCoordinatorStore: ObservableObject {
    var rootFeature: Feature
    
    private let factory: SettingsCoordinatorFactory
    
    init(factory: SettingsCoordinatorFactory) {
        self.factory = factory
        
        rootFeature = factory.makeRootFeature()
    }
    
    
}
