//
//  Router.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 22.05.2025..
//

import Foundation

// MARK: Can be simplifed so handle(step:) doesn't return Bool since now it's typesafe so if decoding for a step passes all will be handled.

@MainActor
protocol Routable<Step>: AnyObject {
    associatedtype Step: Decodable
    var router: any Router<Step> { get }
    func handle(step: Step) async
}

@MainActor
protocol Router<Step> {
    associatedtype Step: Decodable
    var onUnhandledRoute: (Route) async -> Bool { get }
    
    func handle(route: Route) async -> Bool
    func setup(using routable: any Routable<Step>, childRoutables: @escaping () -> [any Routable])
}
