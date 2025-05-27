//
//  RootRouter.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 27.05.2025..
//

import Foundation

class RootRouter<S: Decodable>: Router {
    typealias Step = S
    
    weak private var routable: (any Routable<Step>)?

    private var childRoutables: (() -> [any Routable])?
    
    private var childRouters: [any Router] { childRoutables?().map { $0.router } ?? [] }
    
    var onUnhandledRoute: (Route) async -> Bool = unimplemented(return: false)
    
    func setup(using routable: any Routable<Step>, childRoutables: @escaping () -> [any Routable]) {
        self.routable = routable
        self.childRoutables = childRoutables
        self.onUnhandledRoute = { [weak self] route in
            guard let self else { return false }
            return await self.handle(route: route)
        }
    }
    
    func handle(step: Data) async -> Bool {
        guard let routable else { return false }
        do {
            let step = try JSONDecoder().decode(Step.self, from: step)
            return await routable.handle(step: step)
        } catch {
            return false
        }
    }
    
    func handle(route: Route) async -> Bool {
        let didHandleStep = await handle(step: route.step)
        
        guard didHandleStep else {
            return false
        }
        
        for route in route.children {
            for router in childRouters {
                if await router.handle(route: route) {
                    break
                }
            }
        }
        
        return true
    }
}
