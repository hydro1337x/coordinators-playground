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
    
    func register(routable: any Routable<Step>) {
        self.routable = routable
        
        self.childRoutables = { [weak routable] in
            routable?.childRoutables() ?? []
        }
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

extension Routable {
    func childRoutables() -> [any Routable] {
        var childFeatures: [Feature] = []
        
        if let modalCoordinator = self as? (any ModalCoordinator), let feature = modalCoordinator.destinationFeature {
            childFeatures.append(feature)
        }
        
        if let stackCoordnator = self as? (any StackCoordinator) {
            childFeatures.append(contentsOf: stackCoordnator.pathFeatureValues)
        }
        
        if let tabCoordinator = self as? (any TabCoordinator) {
            childFeatures.append(contentsOf: tabCoordinator.tabFeatureValues)
        }
        
        if let flowCoordinator = self as? (any FlowCoordinator) {
            childFeatures.append(contentsOf: flowCoordinator.flowFeatureValues)
        }
        
        let childRoutables: [any Routable] = childFeatures.compactMap { $0.cast() }
        
        return childRoutables
    }
}
