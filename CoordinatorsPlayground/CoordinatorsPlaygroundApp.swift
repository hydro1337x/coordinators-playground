//
//  CoordinatorsPlaygroundApp.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.05.2025..
//

import SwiftUI

@main
struct CoordinatorsPlaygroundApp: App {
    let authStateStore = AuthStateStore()
    let store: RootCoordinatorStore
    
    init() {
        store = RootCoordinatorStore(authStateStore: authStateStore)
    }
    
    var body: some Scene {
        WindowGroup {
            RootCoordinator(store: store)
                .onOpenURL { url in
                    /**
                     Test via command:
                     xcrun simctl openurl booted "coordinatorsplayground://deeplink?payload=base64encodedData"
                     Example (encode to base64)
                     [
                       { "value": "home" },
                       { "value": "screenA" },
                       { "value": "screenB", "parameters": { "id": "1" } },
                       { "value": "screenC" }
                     ]
                     */
                    Task {
                        await store.handle(routes: DeepLinkParser.parse(url))
                    }
                }
        }
    }
}
