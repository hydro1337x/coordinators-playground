//
//  AccountCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 23.05.2025..
//

import SwiftUI

@MainActor
struct AccountCoordinatorFactory {
    func makeAccountDetails() -> Feature {
        let store = AccountDetailsStore()
        let view = AccountDetailsScreen(store: store).navigationTitle(store.title)
        return Feature(view: view, store: store)
    }
}
