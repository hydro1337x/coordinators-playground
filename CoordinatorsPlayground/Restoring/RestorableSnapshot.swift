//
//  RestorableSnapshot.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 28.05.2025..
//

import Foundation

/// A saved snapshot of a coordinator's state and its children.
struct RestorableSnapshot: Codable {
    /// The serialized state for this coordinator (encoded via `Codable`).
    let state: Data

    /// The saved snapshots of any child coordinators.
    let children: [RestorableSnapshot]
}
