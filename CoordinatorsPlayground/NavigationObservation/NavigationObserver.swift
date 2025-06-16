//
//  NavigationObserver.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 04.06.2025..
//

import Foundation

enum NavigationContext: String {
    case root
    case tab
    case stack
    case modal
    case flow
}

struct NavigationNode {
    let observable: Coordinator
    let context: NavigationContext
    let elevation: Int
}

struct NavigationState {
    let state: AnyHashable
    let observable: Coordinator
    let elevation: Int
    let depth: Int
}

typealias NavigationBranch = [NavigationNode]

import Combine

@MainActor
class NavigationObserver {
    @Published private(set) var topVisibleState: AnyHashable?
    
    private weak var root: Coordinator?
    private var cancellables: Set<AnyCancellable> = []
    private let navigationChangedSubject = PassthroughSubject<AnyHashable, Never>()
    private let scheduler: AnySchedulerOf<RunLoop>
    
    init(scheduler: AnySchedulerOf<RunLoop>) {
        self.scheduler = scheduler
        
        navigationChangedSubject
            .receive(on: scheduler)
            .map { _ in () }
            .debounce(for: .milliseconds(0), scheduler: scheduler)
            .sink { [weak self] in
                self?.resolveTopVisibleState()
            }
            .store(in: &cancellables)
    }
    
    func observe<T>(observable: T, state: KeyPath<T, Published<T.Destination?>.Publisher>) where T: ObservableObject & ModalCoordinator {
        observable[keyPath: state]
            .sink { [navigationChangedSubject] state in
                navigationChangedSubject.send(state)
            }
            .store(in: &cancellables)
    }
    
    func observe<T>(observable: T, state: KeyPath<T, Published<[T.Path]>.Publisher>) where T: ObservableObject & StackCoordinator {
        observable[keyPath: state]
            .sink { [navigationChangedSubject] state in
                navigationChangedSubject.send(state)
            }
            .store(in: &cancellables)
    }
    
    func observe<T>(observable: T, state: KeyPath<T, Published<T.Tab>.Publisher>) where T: ObservableObject & TabsCoordinator {
        observable[keyPath: state]
            .sink { [navigationChangedSubject] state in
                navigationChangedSubject.send(state)
            }
            .store(in: &cancellables)
    }
    
    func observe<T>(observable: T, state: KeyPath<T, Published<T.Flow>.Publisher>) where T: ObservableObject & FlowCoordinator {
        observable[keyPath: state]
            .sink { [navigationChangedSubject] state in
                navigationChangedSubject.send(state)
            }
            .store(in: &cancellables)
    }
    
    func observe<T>(observable: T, flow: KeyPath<T, Published<T.Flow>.Publisher>, destination: KeyPath<T, Published<T.Destination?>.Publisher>) where T: ObservableObject & FlowCoordinator & ModalCoordinator {
        observe(observable: observable, state: flow)
        observe(observable: observable, state: destination)
    }
    
    func observe<T>(observable: T, path: KeyPath<T, Published<[T.Path]>.Publisher>, destination: KeyPath<T, Published<T.Destination?>.Publisher>) where T: ObservableObject & StackCoordinator & ModalCoordinator {
        observe(observable: observable, state: path)
        observe(observable: observable, state: destination)
    }
    
    func register(root observable: Coordinator) {
        self.root = observable
    }
}

extension NavigationObserver {
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
            self.topVisibleState = topVisibleState.state
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

            if let modalObservable = observable as? (any ModalCoordinator), let destination = modalObservable.destination, elevation >= highestElevation {
                highestElevation = elevation + 1
                topVisibleState = NavigationState(state: AnyHashable(destination), observable: observable, elevation: highestElevation, depth: index)
            }

            if let stackObservable = observable as? (any StackCoordinator), let last = stackObservable.path.last, elevation >= highestElevation {
                highestElevation = elevation
                topVisibleState = NavigationState(state: AnyHashable(last), observable: observable, elevation: highestElevation, depth: index)
            }

            if let tabObservable = observable as? (any TabsCoordinator), elevation >= highestElevation {
                highestElevation = elevation
                topVisibleState = NavigationState(state: AnyHashable(tabObservable.tab), observable: observable, elevation: highestElevation, depth: index)
            }

            if let flowObservable = observable as? (any FlowCoordinator), elevation >= highestElevation {
                highestElevation = elevation
                topVisibleState = NavigationState(state: AnyHashable(flowObservable.flow), observable: observable, elevation: highestElevation, depth: index)
            }
        }

        return topVisibleState
    }
    
    private func buildNavigationBranches(
        from observable: Coordinator,
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

        if let modalObservable = observable as? (any ModalCoordinator), let childObservable = modalObservable.destinationFeature?.cast(to: Coordinator.self) {
            let childBranch = buildNavigationBranches(from: childObservable, context: .modal, currentElevation: elevation)
            childBranches.append(contentsOf: childBranch)
        }

        if let stackObservable = observable as? (any StackCoordinator), let last = stackObservable.path.last, let childObservable = stackObservable.erasedPathFeatures[AnyHashable(last)]?.cast(to: Coordinator.self) {
            let childBranch = buildNavigationBranches(from: childObservable, context: .stack, currentElevation: elevation)
            childBranches.append(contentsOf: childBranch)
        }

        if let tabObservable = observable as? (any TabsCoordinator), let childObservable = tabObservable.erasedTabFeatures[AnyHashable(tabObservable.tab)]?.cast(to: Coordinator.self) {
            let childBranch = buildNavigationBranches(from: childObservable, context: .tab, currentElevation: elevation)
            childBranches.append(contentsOf: childBranch)
        }

        if let flowObservable = observable as? (any FlowCoordinator), let childObservable = flowObservable.flowFeature?.cast(to: Coordinator.self) {
            let childBranch = buildNavigationBranches(from: childObservable, context: .flow, currentElevation: elevation)
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

private extension StackCoordinator {
    var erasedPathFeatures: [AnyHashable: Feature] {
        var dict: [AnyHashable: Feature] = [:]
        
        for (key, value) in pathFeatures {
            dict[AnyHashable(key)] = value
        }
        
        return dict
    }
}

private extension TabsCoordinator {
    var erasedTabFeatures: [AnyHashable: Feature] {
        var dict: [AnyHashable: Feature] = [:]
        
        for (key, value) in tabFeatures {
            dict[AnyHashable(key)] = value
        }
        
        return dict
    }
}
