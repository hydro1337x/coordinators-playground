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
        NavigationStack {
            VStack {
                Text("User Bob")
                Spacer()
                Button("Logout") {
                    Task { await store.handleLogoutButtonTapped() }
                }
            }
            .navigationTitle("Account")
        }
    }
}

class AccountCoordinatorStore: ObservableObject {
    var onFinished: () -> Void = {}
    
    private let authStateStore: AuthStateStore
    
    init(authStateStore: AuthStateStore) {
        self.authStateStore = authStateStore
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
    
    @MainActor
    func handleLogoutButtonTapped() async {
        await authStateStore.setState(.loggedOut)
        
        onFinished()
    }
}
