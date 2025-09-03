//
//  Coordinator+Extension.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 17.06.2025..
//

import Foundation

extension StackCoordinator {
    var pathFeatureValues: [Feature] {
        Array(pathFeatures.values)
    }
}

extension TabsCoordinator {
    var tabFeatureValues: [Feature] {
        Array(tabFeatures.values)
    }
}

extension StackCoordinator {
    var erasedPathFeatures: [AnyHashable: Feature] {
        var dict: [AnyHashable: Feature] = [:]
        
        for (key, value) in pathFeatures {
            dict[AnyHashable(key)] = value
        }
        
        return dict
    }
}

extension TabsCoordinator {
    var erasedTabFeatures: [AnyHashable: Feature] {
        var dict: [AnyHashable: Feature] = [:]
        
        for (key, value) in tabFeatures {
            dict[AnyHashable(key)] = value
        }
        
        return dict
    }
}
