//
//  UserDefaultsRestorableSnapshotService.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 17.06.2025..
//

import Foundation

actor UserDefaultsRestorableSnapshotService: SaveRestorableSnapshotService, RetrieveRestorableSnapshotService {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let key = "app-state"
    
    func save(snapshot: RestorableSnapshot) async {
        let json = try? encoder.encode(snapshot)
        defaults.set(json, forKey: key)
    }
    
    func retrieveSnapshot() async -> RestorableSnapshot? {
        guard
            let data = defaults.object(forKey: key) as? Data,
            let snapshot = try? decoder.decode(RestorableSnapshot.self, from: data)
        else { return nil }
        
        return snapshot
    }
}
