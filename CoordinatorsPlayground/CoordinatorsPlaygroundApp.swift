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
        let authStateService = AuthStateProvider()
        let authService = AuthService(service: authStateService)
        let accountCoordinatorFactory = AccountCoordinatorFactory()
        let homeCoordinatorFactory = HomeCoordinatorFactory()
        let tabsCoordinatorFactory = TabsCoordinatorFactory(
            authStateService: authStateService,
            homeCoordinatorFactory: homeCoordinatorFactory
        )
        let rootCoordinatorFactory = RootCoordinatorFactory(
            authStateService: authStateService,
            authService: authService,
            accountCoordinatorFactory: accountCoordinatorFactory,
            tabsCoordinatorFactory: tabsCoordinatorFactory
        )
        store = RootCoordinatorStore(
            authStateService: authStateService,
            authService: authService,
            factory: rootCoordinatorFactory
        )
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
