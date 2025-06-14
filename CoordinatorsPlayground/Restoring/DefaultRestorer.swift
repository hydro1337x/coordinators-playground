//
//  DefaultRestorer.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 28.05.2025..
//

import Foundation

final class DefaultRestorer<S: Codable>: Restorer {
    typealias State = S

    private weak var restorable: (any Restorable<State>)?
    private var childRestorables: (() -> [any Restorable])?
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var childRestorers: [any Restorer] {
        childRestorables?().map { $0.restorer } ?? []
    }

    func register(restorable: any Restorable<State>) {
        self.restorable = restorable
        self.childRestorables = { [weak restorable] in
            restorable?.childRestorables() ?? []
        }
    }

    func restore(from snapshot: RestorableSnapshot) async -> Bool {
        guard let restorable = restorable else { return false }

        do {
            let decodedState = try decoder.decode(State.self, from: snapshot.state)
            await restorable.restore(state: decodedState)

            for childSnapshot in snapshot.children {
                var wasHandled = false

                for childRestorer in childRestorers {
                    if await childRestorer.restore(from: childSnapshot) {
                        wasHandled = true
                        break
                    }
                }

                if !wasHandled {
                    print("⚠️ No child restorer handled a snapshot under \(State.self)")
                }
            }

            return true
        } catch {
            print("⚠️ Failed to decode snapshot for \(State.self): \(error)")
            return false
        }
    }

    func captureHierarchy() async -> RestorableSnapshot {
        guard let restorable = restorable else {
            return RestorableSnapshot(state: Data(), children: [])
        }

        do {
            let state = await restorable.captureState()
            let encodedState = try encoder.encode(state)

            var childSnapshots: [RestorableSnapshot] = []

            for restorer in childRestorers {
                let snapshot = await restorer.captureHierarchy()
                childSnapshots.append(snapshot)
            }

            return RestorableSnapshot(state: encodedState, children: childSnapshots)
        } catch {
            print("⚠️ Failed to encode snapshot for \(State.self): \(error)")
            return RestorableSnapshot(state: Data(), children: [])
        }
    }
}

extension Restorable {
    func childRestorables() -> [any Restorable] {
        var childFeatures: [Feature] = []
        
        if let modalCoordinator = self as? (any ModalCoordinator), let feature = modalCoordinator.destinationFeature {
            childFeatures.append(feature)
        }
        
        if let stackCoordnator = self as? (any StackCoordinator) {
            childFeatures.append(contentsOf: stackCoordnator.pathFeatureValues)
        }
        
        if let tabsCoordinator = self as? (any TabsCoordinator) {
            childFeatures.append(contentsOf: tabsCoordinator.tabFeatureValues)
        }
        
        if let flowCoordinator = self as? (any FlowCoordinator) {
            childFeatures.append(contentsOf: flowCoordinator.flowFeatureValues)
        }
        
        let childRoutables: [any Restorable] = childFeatures.compactMap { $0.cast() }
        
        return childRoutables
    }
}
