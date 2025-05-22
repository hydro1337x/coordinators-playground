//
//  CoordinatorsPlaygroundApp.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.05.2025..
//

import SwiftUI

@main
struct CoordinatorsPlaygroundApp: App {
    let store: RootCoordinatorStore
    
    init() {
        let authStateProvider = AuthStateProvider()
        let loginService = LoginService(authStateProvider: authStateProvider)
        store = RootCoordinatorStore(authStateProvider: authStateProvider, loginService: loginService)
    }
    
    var body: some Scene {
        WindowGroup {
            RootCoordinator(store: store)
                .onOpenURL { url in
                    /**
                     Test via command:
                     xcrun simctl openurl booted "coordinatorsplayground://deeplink?payload=base64EncodedString"
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
