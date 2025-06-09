//
//  HomeCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import SwiftUI

struct HomeCoordinator: View {
    @ObservedObject var store: HomeCoordinatorStore
    
    var body: some View {
        NavigationStack(
            path: .init(
                get: { store.path },
                set: { store.handlePathChanged($0) }
            )
        ) {
            makeRootFeature()
                .navigationDestination(for: HomeCoordinatorStore.Path.self) { path in
                    makeFeature(for: path)
                        .toolbar(content: toolbarButton)
                }
                .navigationTitle("Home Screen")
                .toolbar(content: toolbarButton)
        }
        .sheet(
            item: .binding(
                state: { store.destination },
                with: store.handleDestinationChanged
            ),
            content: { destination in
                switch destination {
                case .screenB:
                    makeDestinatonFeature()
                }
            }
        )
        .task {
            await store.bindObservers()
        }
    }

    func toolbarButton() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            switch store.authState {
            case .loggedIn:
                Button("Account") {
                    store.handleAccountButtonTapped()
                }
            case .loginInProgress:
                ProgressView()
                    .progressViewStyle(.circular)
            case .loggedOut:
                Button("Login") {
                    store.handleLoginButtonTapped()
                }
            case nil:
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    func makeRootFeature() -> some View {
        if let view = store.rootFeature {
            view
        } else {
            Text("Something went wrong")
        }
    }
    
    @ViewBuilder
    func makeDestinatonFeature() -> some View {
        if let view = store.destinationFeature {
            view
        } else {
            Text("Something went wrong")
        }
    }
    
    @ViewBuilder
    func makeFeature(
        for path: HomeCoordinatorStore.Path
    ) -> some View {
        if let view = store.pathFeatures[path] {
            view
        } else {
            Text("Something went wrong")
        }
    }
}
