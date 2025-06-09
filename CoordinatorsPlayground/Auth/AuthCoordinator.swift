//
//  AuthCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import SwiftUI

struct AuthCoordinator: View {
    @ObservedObject var store: AuthCoordinatorStore
    
    var body: some View {
        NavigationStack {
            VStack {
                if store.isLoading {
                    ProgressView()
                } else {
                    Button("Login") {
                        Task { await store.handleLoginTapped() }
                    }
                }
            }
            .navigationTitle("Login")
        }
        .task {
            await store.bindObservers()
        }
    }
}
