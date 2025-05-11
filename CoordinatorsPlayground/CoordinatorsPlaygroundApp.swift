//
//  CoordinatorsPlaygroundApp.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.05.2025..
//

import SwiftUI

@main
struct CoordinatorsPlaygroundApp: App {
    let store = RootCoordinatorStore()
    
    var body: some Scene {
        WindowGroup {
            RootCoordinator(store: store)
                .onOpenURL { url in
                    // Test via command:
                    // xcrun simctl openurl booted "coordinatorsplayground://some/path"
                    store.route(deepLinks: DeepLinkParser.parse(url))
                }
        }
    }
}
