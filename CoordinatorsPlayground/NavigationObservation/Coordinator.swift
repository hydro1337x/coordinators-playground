//
//  NavigationObservable.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import Foundation

@MainActor
protocol Coordinator: AnyObject {}

protocol ModalCoordinator: Coordinator {
    associatedtype Destination: Hashable
    var destination: Destination? { get }
    var destinationFeature: Feature? { get }
}

protocol StackCoordinator: Coordinator {
    associatedtype Path: Hashable
    var path: [Path] { get }
    var pathFeatures: [Path: Feature] { get }
}

protocol TabsCoordinator: Coordinator {
    associatedtype Tab: Hashable
    var tab: Tab { get }
    var tabFeatures: [Tab: Feature] { get }
}

protocol FlowCoordinator: Coordinator {
    associatedtype Flow: Hashable
    var flow: Flow { get }
    var flowFeatures: [Flow: Feature] { get }
}

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

extension FlowCoordinator {
    var flowFeatureValues: [Feature] {
        Array(flowFeatures.values)
    }
}
