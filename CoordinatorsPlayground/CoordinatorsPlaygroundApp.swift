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
    let rootRouter: RootRouter<RootStep>
    
    init() {
        let homeRouter = DefaultRouter<HomeStep>()
        let tabsRouter = DefaultRouter<TabsStep>()
        let accountRouter = DefaultRouter<AccountStep>()
        rootRouter = RootRouter<RootStep>()
        
        homeRouter.onUnhandledRoute = { [weak tabsRouter] route in
            guard let tabsRouter else { return false }
            return await tabsRouter.onUnhandledRoute(route)
        }
        
        tabsRouter.onUnhandledRoute = { [weak rootRouter] route in
            guard let rootRouter else { return false }
            return await rootRouter.onUnhandledRoute(route)
        }
        
        accountRouter.onUnhandledRoute = { [weak rootRouter] route in
            guard let rootRouter else { return false }
            return await rootRouter.onUnhandledRoute(route)
        }
        
        let themeManager = ThemeManager()
        let authStateService = AuthStateProvider()
        let authService = AuthService(service: authStateService)
        let accountCoordinatorFactory = AccountCoordinatorFactory()
        let homeCoordinatorFactory = HomeCoordinatorFactory()
        let tabsCoordinatorFactory = TabsCoordinatorFactory(
            authStateService: authStateService,
            homeCoordinatorFactory: homeCoordinatorFactory,
            homeRouter: homeRouter
        )
        let rootCoordinatorFactory = RootCoordinatorFactory(
            authStateService: authStateService,
            authService: authService,
            accountCoordinatorFactory: accountCoordinatorFactory,
            tabsCoordinatorFactory: tabsCoordinatorFactory,
            themeManager: themeManager,
            tabsRouter: tabsRouter,
            accountRouter: accountRouter
        )
        _themeManager = StateObject(wrappedValue: themeManager)
        store = RootCoordinatorStore(
            authStateService: authStateService,
            authService: authService,
            factory: rootCoordinatorFactory,
            router: rootRouter
        )
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
                            print("Parsing failed")
                            return
                        }
                        
                        let didHandleRoute = await rootRouter.handle(route: route)
                        
                        if !didHandleRoute {
                            print("⚠️ Unhandled route step: \(route.step)")
                        }
                    }
                }
        }
    }
}
