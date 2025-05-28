//
//  CoordinatorsPlaygroundApp.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.05.2025..
//

import SwiftUI

@main
struct CoordinatorsPlaygroundApp: App {
//    @Environment(\.scenePhase) var scenePhase
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
//                .onChange(of: scenePhase) { newPhase in
//                    if newPhase == .background {
//                        do {
//                            let data = try store.saveState()
//                            UserDefaults.standard.set(data, forKey: "app-state")
//                        } catch {
//                            print("State restoration error: \(error)")
//                        }
//                    }
//                }
//                .onAppear {
//                    guard let data = UserDefaults.standard.object(forKey: "app-state") as? [Data] else { return }
//                    do {
//                        try store.restoreState(from: data)
//                    } catch {
//                        print("State restoration error: \(error)")
//                    }
//                }
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
