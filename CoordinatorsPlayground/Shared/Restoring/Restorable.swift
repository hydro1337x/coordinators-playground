//
//  Restorable.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 28.05.2025..
//

import Foundation

@MainActor
protocol Restorable<State>: AnyObject {
    associatedtype State: Codable

    /// The restorer responsible for restoring this coordinator.
    var restorer: any Restorer<State> { get }

    /// Capture the current state of the coordinator.
    func captureState() async -> State

    /// Restore the coordinator using the decoded state.
    func restore(state: State) async
}
