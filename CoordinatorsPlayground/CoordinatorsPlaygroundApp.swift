//
//  CoordinatorsPlaygroundApp.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.05.2025..
//

import SwiftUI

@main
struct CoordinatorsPlaygroundApp: App {
    @State var firstAppear = true
    @Environment(\.scenePhase) var scenePhase
    @StateObject var themeManager: ThemeManager
    let store: RootCoordinatorStore
    
    init() {
        let dependencies = Dependencies()
        _themeManager = StateObject(wrappedValue: dependencies.themeManager)
        store = dependencies.makeRootCoordinatorStore()
    }
    
    var body: some Scene {
        WindowGroup {
            RootCoordinator(store: store)
                .environment(\.theme, themeManager.currentTheme)
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background {
                        Task {
                            let snapshot = await store.restorer.captureHierarchy()
                            let json = try? JSONEncoder().encode(snapshot)
                            UserDefaults.standard.set(json, forKey: "app-state")
                        }
                    }
                }
                .onAppear {
                    if firstAppear {
                        defer { firstAppear = false }
                        Task {
                            guard let data = UserDefaults.standard.object(forKey: "app-state") as? Data, let snapshot = try? JSONDecoder().decode(RestorableSnapshot.self, from: data) else { return }
                            _ = await store.restorer.restore(from: snapshot)
                        }
                    }
                }
                .onOpenURL { url in
                    /**
                     Test via command:
                     xcrun simctl openurl booted "coordinatorsplayground://deeplink?payload=base64EncodedString"
                     */
                    Task {
                        guard let route = DeepLinkParser.parse(url) else {
                            return
                        }
                        
                        _ = await store.router.handle(route: route)
                    }
                }
        }
    }
}
