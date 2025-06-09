//
//  Binding+Extension.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import SwiftUI

extension Binding {
    static func binding<State>(
        state: @MainActor @escaping () -> State,
        with action: @MainActor @escaping (State) -> Void
    ) -> Binding<State> {
        Binding<State>(get: state, set: action)
    }
}
