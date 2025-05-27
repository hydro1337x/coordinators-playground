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
protocol Router<Step>: AnyObject {
    associatedtype Step: Decodable
    var onUnhandledRoute: (Route) async -> Bool { get }
    
    func handle(route: Route) async -> Bool
    func setup(using routable: any Routable<Step>, childRoutables: @escaping () -> [any Routable])
}

//final class LoggingRouterDecorator<Step: Decodable>: Router {
//    private let wrapped: any Router<Step>
//    private let logger: (String) -> Void
//
//    init(wrapping router: some Router<Step>, logger: @escaping (String) -> Void = { print($0) }) {
//        self.wrapped = router
//        self.logger = logger
//    }
//
//    var onUnhandledRoute: (Route) async -> Bool {
//        wrapped.onUnhandledRoute
//    }
//
//    func setup(using routable: any Routable<Step>, childRoutables: @escaping () -> [any Routable]) {
//        logger("Router setup with \(routable)")
//        wrapped.setup(using: routable, childRoutables: childRoutables)
//    }
//
//    func handle(route: Route) async -> Bool {
//        logger("Handling route: \(route)")
//        let result = await wrapped.handle(route: route)
//        logger("Handled route: \(route), success: \(result)")
//        return result
//    }
//}
