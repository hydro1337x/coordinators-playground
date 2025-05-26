//
//  Router.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 22.05.2025..
//

import Foundation

@MainActor
protocol Router {
    associatedtype Step: Decodable
    
    var onUnhandledRoute: (Route) async -> Bool { get }
    var childRouters: [any Router] { get }
    
    func handle(route: Route) async -> Bool
    func handle(step: Step) async -> Bool
}

extension Router {
    func handle(step: Data) async -> Bool {
        do {
            let step = try JSONDecoder().decode(Step.self, from: step)
            return await handle(step: step)
        } catch {
            return false
        }
    }
    
    func handle(route: Route) async -> Bool {
        let didHandleStep = await handle(step: route.step)
        
        guard didHandleStep else {
            return await onUnhandledRoute(route)
        }
        
        return await handle(childRoutes: route.children, using: childRouters)
    }
    
    func handle(childRoutes: [Route], using childRouters: [any Router]) async -> Bool {
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

@MainActor
protocol StateRestoring {
    func saveState() throws -> [Data]
    func restoreState(from data: [Data]) throws
}

extension StateRestoring {
    func encode<T: Encodable>(_ state: T) throws -> Data {
        try JSONEncoder().encode(state)
    }
    
    func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        try JSONDecoder().decode(T.self, from: data)
    }
}
