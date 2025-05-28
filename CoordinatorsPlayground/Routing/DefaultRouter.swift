//
//  DefaultRouter.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 27.05.2025..
//

import Foundation

class DefaultRouter<S: Decodable>: Router {
    typealias Step = S
    
    weak private var routable: (any Routable<Step>)?
    private var childRoutables: (() -> [any Routable])?
    
    private var childRouters: [any Router] { childRoutables?().map { $0.router } ?? [] }
    
    var onUnhandledRoute: (Route) async -> Bool = unimplemented(return: false)
    
    private let decoder = JSONDecoder()
    
    func setup(using routable: any Routable<Step>, childRoutables: @escaping () -> [any Routable]) {
        self.routable = routable
        self.childRoutables = childRoutables
    }
    
    func handle(step: Data) async -> Bool {
        guard let routable else { return false }
        do {
            let step = try decoder.decode(Step.self, from: step)
            await routable.handle(step: step)
            return true
        } catch {
            return false
        }
    }
    
    func handle(route: Route) async -> Bool {
        let didHandleStep = await handle(step: route.step)
        
        guard didHandleStep else {
            return await onUnhandledRoute(route)
        }
        
        return await handle(childRoutes: route.children)
    }
    
    func handle(childRoutes: [Route]) async -> Bool {
        for route in childRoutes {
            var didHandleStep = false
            
            for router in childRouters {
                if await router.handle(route: route) {
                    didHandleStep = true
                    break
                }
            }
            
            // If none of the child routers handled this child route
            // Maybe append routes which are unhandled and then interate over them and call onUnhandledRoute -> test this
            if !didHandleStep {
                return await onUnhandledRoute(route)
            }
        }
        
        return true
    }
}
