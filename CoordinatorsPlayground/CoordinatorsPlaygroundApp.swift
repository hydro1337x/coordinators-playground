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
        }
    }
}

@MainActor
final class AppStore: ObservableObject {
    @Published var currentTheme: Theme
    
    let rootCoordinator: Feature
    let themeStore: ThemeStore
    let snapshotService: SaveRestorableSnapshotService & RetrieveRestorableSnapshotService
    
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
        restoreState()
    }
    
    func handleOnURLOpen(_ url: URL) {
        /**
         Test via command:
         xcrun simctl openurl booted "coordinatorsplayground://deeplink?payload=base64EncodedString"
         */
        Task {
            guard let route = DeepLinkParser.parse(url) else {
                return
            }
            
            _ = await rootCoordinator.as(type: (any Routable).self)?.router.handle(route: route)
        }
    }
    
    private func restoreState() {
        Task {
            guard let snapshot = await snapshotService.retrieveSnapshot() else { return }
            _ = await rootCoordinator.as(type: (any Restorable).self)?.restorer.restore(from: snapshot)
        }
    }
    
    private func saveState() {
        Task {
            guard let snapshot = await rootCoordinator.as(type: (any Restorable).self)?.restorer.captureHierarchy() else { return }
            await snapshotService.save(snapshot: snapshot)
        }
    }
}
