//
//  NavigationObservable.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import Foundation

@MainActor
protocol NavigationObservable: AnyObject {}

protocol ModalNavigationObservable: NavigationObservable {
    associatedtype Destination: Hashable
    var destination: Destination? { get }
    var destinationFeature: Feature? { get }
}

protocol StackNavigationObservable: NavigationObservable {
    associatedtype Path: Hashable
    var path: [Path] { get }
    var pathFeatures: [Path: Feature] { get }
}

protocol TabNavigationObservable: NavigationObservable {
    associatedtype Tab: Hashable
    var tab: Tab { get }
    var tabFeatures: [Tab: Feature] { get }
}

protocol FlowNavigationObservable: NavigationObservable {
    associatedtype Flow: Hashable
    var flow: Flow { get }
    var flowFeatures: [Flow: Feature] { get }
}
