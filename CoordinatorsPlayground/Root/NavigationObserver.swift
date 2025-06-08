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

enum PresentationType: String {
    case root
    case tab
    case stack
    case modal
    case flow
}

struct NavigationGraphNode {
    let coordinator: NavigationObservable
    let presentation: PresentationType
    let elevation: Int
}

struct NavigationState {
    let state: AnyHashable
    let coordinator: NavigationObservable
    let elevation: Int
    let depth: Int
}

typealias NavigationGraphBranch = [NavigationGraphNode]

@MainActor
class NavigationObserver {
    private weak var root: NavigationObservable?
    
    func calculateTop() {
        guard let root else { return }
        let branches = calculateGraphBranches(from: root)
        let topMostStates = branches.compactMap {
            findTopmostState(in: $0)
        }
        let topMost = topMostStates.sorted(by: { lhs, rhs in
            if lhs.elevation > rhs.elevation {
                return true
            } else if lhs.elevation == rhs.elevation {
                return lhs.depth > rhs.depth
            } else {
                return false
            }
        }).first
        
        if let topMost {
            print("📍 Topmost: \(topMost.state) in \(type(of: topMost.coordinator))")
        } else {
            print("⚠️ No topmost state found")
        }
    }
    
    func findTopmostState(in branch: [NavigationGraphNode]) -> NavigationState? {
        var highestElevation = -1
        var topMostState: NavigationState?

        for (index, node) in branch.enumerated() {
            let elevation = node.elevation
            let coordinator = node.coordinator

            if let modal = coordinator as? (any ModalNavigationObservable), let destination = modal.destination, elevation >= highestElevation {
                highestElevation = elevation + 1
                topMostState = NavigationState(state: AnyHashable(destination), coordinator: coordinator, elevation: highestElevation, depth: index)
            }

            if let stack = coordinator as? (any StackNavigationObservable), let last = stack.path.last, elevation >= highestElevation {
                highestElevation = elevation
                topMostState = NavigationState(state: AnyHashable(last), coordinator: coordinator, elevation: highestElevation, depth: index)
            }

            if let tab = coordinator as? (any TabNavigationObservable), elevation >= highestElevation {
                highestElevation = elevation
                topMostState = NavigationState(state: AnyHashable(tab.tab), coordinator: coordinator, elevation: highestElevation, depth: index)
            }

            if let flow = coordinator as? (any FlowNavigationObservable), elevation >= highestElevation {
                highestElevation = elevation
                topMostState = NavigationState(state: AnyHashable(flow.flow), coordinator: coordinator, elevation: highestElevation, depth: index)
            }
        }

        return topMostState
    }
    
    func calculateGraphBranches(
        from coordinator: NavigationObservable,
        presentation: PresentationType = .root,
        currentElevation: Int = 0
    ) -> [[NavigationGraphNode]] {
        // Determine this level's elevation
        let elevation = (presentation == .modal) ? currentElevation + 1 : currentElevation

        // Start node
        let node = NavigationGraphNode(
            coordinator: coordinator,
            presentation: presentation,
            elevation: elevation
        )

        // Recursively get all children branches
        var childBranches: [[NavigationGraphNode]] = []

        if let modal = coordinator as? (any ModalNavigationObservable),
           let destination = modal.destinationFeature?.cast(to: NavigationObservable.self) {
            let nested = calculateGraphBranches(from: destination, presentation: .modal, currentElevation: elevation)
            childBranches.append(contentsOf: nested)
        }

        if let stack = coordinator as? (any StackNavigationObservable), let last = stack.path.last, let destination = stack.erasedPathFeatures[AnyHashable(last)]?.cast(to: NavigationObservable.self) {
            let nested = calculateGraphBranches(from: destination, presentation: .stack, currentElevation: elevation)
            childBranches.append(contentsOf: nested)
        }

        if let tab = coordinator as? (any TabNavigationObservable), let destination = tab.erasedTabFeatures[AnyHashable(tab.tab)]?.cast(to: NavigationObservable.self) {
            let nested = calculateGraphBranches(from: destination, presentation: .tab, currentElevation: elevation)
            childBranches.append(contentsOf: nested)
        }

        if let flow = coordinator as? (any FlowNavigationObservable), let destination = flow.erasedFlowFeatures[AnyHashable(flow.flow)]?.cast(to: NavigationObservable.self) {
            let nested = calculateGraphBranches(from: destination, presentation: .flow, currentElevation: elevation)
            childBranches.append(contentsOf: nested)
        }

        // If no children, return a leaf branch
        if childBranches.isEmpty {
            return [[node]]
        }

        // Attach current node to each child branch
        return childBranches.map { [node] + $0 }
    }
    
    func register(root observable: NavigationObservable) {
        observable.onNavigationChanged = { [weak self] in
            self?.calculateTop()
        }
        
        self.root = observable
    }
    
    func register(child observable: NavigationObservable) {
        observable.onNavigationChanged = { [weak self] in
            self?.calculateTop()
        }
    }
}
