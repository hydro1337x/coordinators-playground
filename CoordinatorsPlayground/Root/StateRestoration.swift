//
//  StateRestoration.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 27.05.2025..
//

import Foundation

@MainActor
protocol StateRestoring {
    func saveState() throws -> [Data]
    func restoreState(from data: [Data]) throws
}

extension StateRestoring {
    func encode<T: Encodable>(_ state: T) throws -> Data {
        try JSONEncoder().encode(state)
    }
    
    func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        try JSONDecoder().decode(T.self, from: data)
    }
}
