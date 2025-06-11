//
//  AccountCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 12.05.2025..
//

import SwiftUI

struct AccountCoordinator: View {
    @ObservedObject var store: AccountCoordinatorStore
    let makeFloatingStack: () -> AnyView
    
    var body: some View {
        NavigationStack(path: .binding(state: { store.path }, with: store.handlePathChanged)) {
            makeRootFeature()
                .navigationDestination(for: AccountCoordinatorStore.Path.self) { path in
                    switch path {
                    case .details:
                        makeFeature(for: path)
                    }
                }
                .navigationTitle("Account")
        }
        .sheet(item: .binding(
                    state: { store.destination?.sheet },
                    with: store.handleSheetChanged
                )
        ) { sheet in
            switch sheet {
            case .help:
                makeDestinatonFeature()
            }
        }
        .overlay {
            makeFloatingStack()
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
    func makeFeature(for path: AccountCoordinatorStore.Path) -> some View {
        if let view = store.pathFeatures[path] {
            view
        } else {
            Text("Something went wrong")
        }
    }
}


