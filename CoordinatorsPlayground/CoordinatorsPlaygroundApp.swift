//
//  CoordinatorsPlaygroundApp.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.05.2025..
//

import SwiftUI

@main
struct CoordinatorsPlaygroundApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var store: AppStore
    
    init() {
        let dependencies = Dependencies()
        _store = StateObject(wrappedValue: dependencies.makeAppStore())
    }
    
    var body: some Scene {
        WindowGroup {
            store.rootCoordinator
                .environment(\.theme, store.currentTheme)
                .onChange(of: scenePhase, perform: store.handleScenePhaseChanged)
                .onFirstAppear(perform: store.handleOnFirstAppear)
                .onOpenURL(perform: store.handleOnURLOpen)
                .animation(.default, value: store.currentTheme)
        }
    }
}

@MainActor
final class AppStore: ObservableObject {
    @Published var currentTheme: Theme
    
    let rootCoordinator: Feature
    let themeStore: ThemeStore
    let snapshotService: SaveRestorableSnapshotService & RetrieveRestorableSnapshotService
    
    private var pendingURL: URL?
    
    init(
        makeRootFeature: () -> Feature,
        themeStore: ThemeStore,
        snapshotService: SaveRestorableSnapshotService & RetrieveRestorableSnapshotService
    ) {
        self.rootCoordinator = makeRootFeature()
        self.currentTheme = themeStore.currentTheme
        self.themeStore = themeStore
        self.snapshotService = snapshotService
    }
    
    private func bind() {
        themeStore.$currentTheme.assign(to: &$currentTheme)
    }
    
    func handleScenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .background:
            saveState()
        case .inactive, .active:
            break
        @unknown default:
            break
        }
    }
    
    func handleOnFirstAppear() {
        bind()
        themeStore.handleOnFirstAppear()
        
        Task {
            await restoreState()
            await handleDeepLink()
        }
    }
    
    func handleOnURLOpen(_ url: URL) {
        self.pendingURL = url
        /**
         Test via command:
         xcrun simctl openurl booted "coordinatorsplayground://deeplink?payload=base64EncodedString"
         */
    }
    
    private func handleDeepLink() async {
        guard
            let pendingURL,
            let route = DeepLinkParser.parse(pendingURL),
            let restorable: any Routable = rootCoordinator.cast()
        else { return }
        
        _ = await restorable.router.handle(route: route)
        
        self.pendingURL = nil
    }
    
    private func restoreState() async {
        guard
            let snapshot = await snapshotService.retrieveSnapshot(),
            let restorable: any Restorable = rootCoordinator.cast()
        else { return }
        _ = await restorable.restorer.restore(from: snapshot)
    }
    
    private func saveState() {
        Task {
            guard let restorable: any Restorable = rootCoordinator.cast() else { return }
            let snapshot = await restorable.restorer.captureHierarchy()
            await snapshotService.save(snapshot: snapshot)
        }
    }
}
