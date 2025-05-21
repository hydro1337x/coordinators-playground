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
                     xcrun simctl openurl booted "coordinatorsplayground://deeplink?payload=ewogICJzdGVwIjogewogICAgInR5cGUiOiAiZmxvdyIsCiAgICAidmFsdWUiOiAidGFicyIKICB9LAogICJjaGlsZHJlbiI6IFsKICAgIHsKICAgICAgInN0ZXAiOiB7CiAgICAgICAgInR5cGUiOiAidGFiIiwKICAgICAgICAidmFsdWUiOiAiaG9tZSIKICAgICAgfSwKICAgICAgImNoaWxkcmVuIjogWwogICAgICAgIHsKICAgICAgICAgICJzdGVwIjogewogICAgICAgICAgICAidHlwZSI6ICJwcmVzZW50IiwKICAgICAgICAgICAgInZhbHVlIjogewogICAgICAgICAgICAgICJ2YWx1ZSI6ICJhY2NvdW50IiwKICAgICAgICAgICAgICAiYXV0aFRva2VuIjogInNlY3JldFRva2VuIgogICAgICAgICAgICB9CiAgICAgICAgICB9LAogICAgICAgICAgImNoaWxkcmVuIjogW10KICAgICAgICB9CiAgICAgIF0KICAgIH0KICBdCn0="
                     Example (encode to base64)
                     [
                       { "value": "home" },
                       { "value": "screenA" },
                       { "value": "screenB", "parameters": { "id": "1" } },
                       { "value": "screenC" }
                     ]
                     */
                    Task {
                        guard let route = DeepLinkParser.parse(url) else {
                            print("Parsing failed")
                            return
                        }
                        
                        let didHandleRoute = await store.handle(route: route)
                        
                        if !didHandleRoute {
                            print("⚠️ Unhandled route step: \(route.step)")
                        }
                    }
                }
        }
    }
}
