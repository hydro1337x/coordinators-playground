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


@MainActor
class AuthCoordinatorStore: ObservableObject {
    @Published var isLoading = false
    
    var onFinished: () -> Void = {}
    let authStateStore: AuthStateStore
    
    init(authStateStore: AuthStateStore) {
        self.authStateStore = authStateStore
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
    
    func bindObservers() async {
        for await state in await authStateStore.values {
            switch state {
            case .loginInProgress:
                isLoading = true
            case .loggedIn, .loggedOut:
                isLoading = false
            }
        }
    }
    
    func handleLoginTapped() async {
        await authStateStore.setState(.loginInProgress)
        
        try? await Task.sleep(for: .seconds(2))
        
        await authStateStore.setState(.loggedIn)
        
        onFinished()
    }
}
