//
//  NavigationObserver.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 04.06.2025..
//

import Foundation

@MainActor
protocol NavigationObservable: AnyObject {
    var onNavigationChanged: () -> Void { get set }
}

protocol ModalNavigationObservable: NavigationObservable {
    associatedtype Destination: Hashable
    var destination: Destination? { get }
    var destinationFeature: Feature? { get }
}

protocol StackNavigationObservable: NavigationObservable {
    associatedtype Path: Hashable
    var path: [Path] { get }
    var pathFeatures: [Path: Feature] { get }
}

private extension StackNavigationObservable {
    var erasedPathFeatures: [AnyHashable: Feature] {
        var dict: [AnyHashable: Feature] = [:]
        
        for (key, value) in pathFeatures {
            dict[AnyHashable(key)] = value
        }
        
        return dict
    }
}

protocol TabNavigationObservable: NavigationObservable {
    associatedtype Tab: Hashable
    var tab: Tab { get }
    var tabFeatures: [Tab: Feature] { get }
}

extension TabNavigationObservable {
    var erasedTabFeatures: [AnyHashable: Feature] {
        var dict: [AnyHashable: Feature] = [:]
        
        for (key, value) in tabFeatures {
            dict[AnyHashable(key)] = value
        }
        
        return dict
    }
}

protocol FlowNavigationObservable: NavigationObservable {
    associatedtype Flow: Hashable
    var flow: Flow { get }
    var flowFeatures: [Flow: Feature] { get }
}

extension FlowNavigationObservable {
    var erasedFlowFeatures: [AnyHashable: Feature] {
        var dict: [AnyHashable: Feature] = [:]
        
        for (key, value) in flowFeatures {
            dict[AnyHashable(key)] = value
        }
        
        return dict
    }
}

enum NavigationContext: String {
    case root
    case tab
    case stack
    case modal
    case flow
}

struct NavigationNode {
    let observable: NavigationObservable
    let context: NavigationContext
    let elevation: Int
}

struct NavigationState {
    let state: AnyHashable
    let observable: NavigationObservable
    let elevation: Int
    let depth: Int
}

typealias NavigationBranch = [NavigationNode]

@MainActor
class NavigationObserver {
    private weak var root: NavigationObservable?
    
    func register(root observable: NavigationObservable) {
        observable.onNavigationChanged = { [weak self] in
            self?.resolveTopVisibleState()
        }
        
        self.root = observable
    }
    
    func register(child observable: NavigationObservable) {
        observable.onNavigationChanged = { [weak self] in
            self?.resolveTopVisibleState()
        }
    }
    
    private func resolveTopVisibleState() {
        guard let root else { return }
        let branches = buildNavigationBranches(from: root)
        let topVisibleStates = branches.compactMap {
            resolveTopVisibleState(in: $0)
        }
        let topVisibleState = topVisibleStates.sorted(by: { lhs, rhs in
            if lhs.elevation > rhs.elevation {
                return true
            } else if lhs.elevation == rhs.elevation {
                return lhs.depth > rhs.depth
            } else {
                return false
            }
        }).first
        
        if let topVisibleState {
            print("📍 Topmost: \(topVisibleState.state) in \(type(of: topVisibleState.observable))")
        } else {
            print("⚠️ No topmost state found")
        }
    }
    
    private func resolveTopVisibleState(in branch: NavigationBranch) -> NavigationState? {
        var highestElevation = -1
        var topVisibleState: NavigationState?

        for (index, node) in branch.enumerated() {
            let elevation = node.elevation
            let observable = node.observable

            if let modalObservable = observable as? (any ModalNavigationObservable), let destination = modalObservable.destination, elevation >= highestElevation {
                highestElevation = elevation + 1
                topVisibleState = NavigationState(state: AnyHashable(destination), observable: observable, elevation: highestElevation, depth: index)
            }

            if let stackObservable = observable as? (any StackNavigationObservable), let last = stackObservable.path.last, elevation >= highestElevation {
                highestElevation = elevation
                topVisibleState = NavigationState(state: AnyHashable(last), observable: observable, elevation: highestElevation, depth: index)
            }

            if let tabObservable = observable as? (any TabNavigationObservable), elevation >= highestElevation {
                highestElevation = elevation
                topVisibleState = NavigationState(state: AnyHashable(tabObservable.tab), observable: observable, elevation: highestElevation, depth: index)
            }

            if let flowObservable = observable as? (any FlowNavigationObservable), elevation >= highestElevation {
                highestElevation = elevation
                topVisibleState = NavigationState(state: AnyHashable(flowObservable.flow), observable: observable, elevation: highestElevation, depth: index)
            }
        }

        return topVisibleState
    }
    
    private func buildNavigationBranches(
        from observable: NavigationObservable,
        context: NavigationContext = .root,
        currentElevation: Int = 0
    ) -> [NavigationBranch] {
        // Determine this level's elevation
        let elevation = (context == .modal) ? currentElevation + 1 : currentElevation

        // Start node
        let node = NavigationNode(
            observable: observable,
            context: context,
            elevation: elevation
        )

        // Recursively get all children branches
        var childBranches: [NavigationBranch] = []

        if let modalObservable = observable as? (any ModalNavigationObservable),
           let destination = modalObservable.destinationFeature?.cast(to: NavigationObservable.self) {
            let childBranch = buildNavigationBranches(from: destination, context: .modal, currentElevation: elevation)
            childBranches.append(contentsOf: childBranch)
        }

        if let stackObservable = observable as? (any StackNavigationObservable), let last = stackObservable.path.last, let destination = stackObservable.erasedPathFeatures[AnyHashable(last)]?.cast(to: NavigationObservable.self) {
            let childBranch = buildNavigationBranches(from: destination, context: .stack, currentElevation: elevation)
            childBranches.append(contentsOf: childBranch)
        }

        if let tabObservable = observable as? (any TabNavigationObservable), let destination = tabObservable.erasedTabFeatures[AnyHashable(tabObservable.tab)]?.cast(to: NavigationObservable.self) {
            let childBranch = buildNavigationBranches(from: destination, context: .tab, currentElevation: elevation)
            childBranches.append(contentsOf: childBranch)
        }

        if let flowObservable = observable as? (any FlowNavigationObservable), let destination = flowObservable.erasedFlowFeatures[AnyHashable(flowObservable.flow)]?.cast(to: NavigationObservable.self) {
            let childBranch = buildNavigationBranches(from: destination, context: .flow, currentElevation: elevation)
            childBranches.append(contentsOf: childBranch)
        }

        // If no children, return a leaf branch
        if childBranches.isEmpty {
            return [[node]]
        }

        // Attach current node to each child branch
        return childBranches.map { [node] + $0 }
    }
}
