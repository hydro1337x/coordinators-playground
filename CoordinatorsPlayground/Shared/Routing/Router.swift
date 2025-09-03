//
//  Router.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 22.05.2025..
//

import Foundation

@MainActor
protocol Router<Step> {
    associatedtype Step: Decodable
    
    var onUnhandledRoute: (Route) async -> Bool { get }
    
    func handle(route: Route) async -> Bool
    func register(routable: any Routable<Step>)
}
