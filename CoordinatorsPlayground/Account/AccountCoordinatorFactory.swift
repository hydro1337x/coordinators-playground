//
//  DefaultAccountCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 23.05.2025..
//

import SwiftUI

@MainActor
protocol AccountCoordinatorFactory {
    func makeAccountDetails() -> Feature
    func makeAccountHelp(onDismiss: @escaping () -> Void) -> Feature
}

struct DefaultAccountCoordinatorFactory: AccountCoordinatorFactory {
    func makeAccountDetails() -> Feature {
        let store = AccountDetailsStore()
        let view = AccountDetailsScreen(store: store).navigationTitle(store.title)
        return Feature(view: view, store: store)
    }
    
    func makeAccountHelp(onDismiss: @escaping () -> Void) -> Feature {
        let store = AccountHelpStore()
        store.onDismiss = onDismiss
        let view = AccountHelpScreen(store: store).navigationTitle(store.title)
        return Feature(view: view, store: store)
    }
}
