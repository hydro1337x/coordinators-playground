//
//  RestorableSnapshotService.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 29.05.2025..
//

import Foundation

protocol SaveRestorableSnapshotService: Sendable {
    func save(snapshot: RestorableSnapshot) async
}

protocol RetrieveRestorableSnapshotService: Sendable {
    func retrieveSnapshot() async -> RestorableSnapshot?
}
