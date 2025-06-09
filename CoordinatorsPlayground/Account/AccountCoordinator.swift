//
//  AccountCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 12.05.2025..
//

import SwiftUI

struct AccountCoordinator: View {
    @ObservedObject var store: AccountCoordinatorStore
    
    var body: some View {
        NavigationStack(path: .binding(state: { store.path }, with: store.handlePathChanged)) {
            VStack {
                Text("User Bob Account")
                VStack {
                    Button("Push Details") {
                        store.handleShowDetailsButtonTapped()
                    }
                    Button("Present Help") {
                        store.handlePresentHelpButtonTapped()
                    }
                    Text("Theme")
                    HStack {
                        Button("Light") {
                            Task {  await store.handleLightThemeButtonTapped() }
                        }
                        
                        Button("Dark") {
                            Task { await store.handleDarkThemeButtonTapped() }
                        }
                    }
                }
                Spacer()
                Button("Logout") {
                    Task { await store.handleLogoutButtonTapped() }
                }
            }
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


