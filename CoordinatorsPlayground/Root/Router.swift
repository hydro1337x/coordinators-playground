//
//  Router.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 22.05.2025..
//

import Foundation

@MainActor
protocol Router {
    var onUnhandledRoute: (Route) async -> Bool { get }
    func handle(route: Route) async -> Bool
}

extension Router {
    func handle(childRoutes: [Route], using childRouters: [Router]) async -> Bool {
        for route in childRoutes {
            var didHandleStep = false
            
            for router in childRouters {
                if await router.handle(route: route) {
                    didHandleStep = true
                    break
                }
            }
            
            // If none of the child routers handled this child route
            if !didHandleStep {
                return await onUnhandledRoute(route)
            }
        }
        
        return true
    }
}
