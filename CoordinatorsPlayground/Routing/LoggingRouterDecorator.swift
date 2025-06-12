//
//  LoggingRouterDecorator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 27.05.2025..
//

import Foundation

struct LoggingRouterDecorator<Step: Decodable>: Router {
    private let decoratee: any Router<Step>

    var onUnhandledRoute: (Route) async -> Bool {
        get { decoratee.onUnhandledRoute }
    }

    init(decorating decoratee: any Router<Step>) {
        self.decoratee = decoratee
    }

    func register(routable: any Routable<Step>) {
        decoratee.register(routable: routable)
    }

    func handle(route: Route) async -> Bool {
        printRoute(route)
        return await decoratee.handle(route: route)
    }

    private func printRoute(_ route: Route) {
        if let stepDict = decodeJSONToDict(route.step) {
            print("➡️ Route Step: \(stepDict)")
        } else {
            print("❓ Could not decode step")
        }
    }

    private func decodeJSONToDict(_ data: Data) -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            return nil
        }
    }
}
