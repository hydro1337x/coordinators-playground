//
//  Router.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 22.05.2025..
//

import Foundation

@MainActor
protocol Routable<Step>: Coordinator {
    associatedtype Step: Decodable
    var router: any Router<Step> { get }
    func handle(step: Step) async
}

@MainActor
protocol Router<Step> {
    associatedtype Step: Decodable
    var onUnhandledRoute: (Route) async -> Bool { get }
    
    func handle(route: Route) async -> Bool
    func register(routable: any Routable<Step>)
}
