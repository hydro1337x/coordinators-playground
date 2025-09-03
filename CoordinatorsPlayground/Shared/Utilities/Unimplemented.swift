//
//  Unimplemented.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 22.05.2025..
//

import Foundation

func unimplemented<T, U>(
  _ name: String = #function,
  return defaultValue: U
) -> (T) async -> U {
    return { _ in
        assertionFailure("⚠️ Unimplemented closure: \(name)")
        return defaultValue
    }
}

func unimplemented<T>(
  _ name: String = #function
) -> (T) -> Void {
    return { _ in
        assertionFailure("⚠️ Unimplemented closure: \(name)")
    }
}

func unimplemented(
  _ name: String = #function
) -> () -> Void {
    return {
        assertionFailure("⚠️ Unimplemented closure: \(name)")
    }
}
