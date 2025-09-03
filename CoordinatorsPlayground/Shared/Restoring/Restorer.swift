//
//  Restorer.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 28.05.2025..
//

import Foundation

@MainActor
protocol Restorer<State> {
    associatedtype State: Codable

    /// Set up this restorer with its associated restorable and child restorables.
    func register(restorable: any Restorable<State>)

    /// Attempt to restore this coordinator (and children) from the given snapshot.
    func restore(from snapshot: RestorableSnapshot) async -> Bool

    /// Create a snapshot of this coordinator and all of its children.
    func captureHierarchy() async -> RestorableSnapshot
}
