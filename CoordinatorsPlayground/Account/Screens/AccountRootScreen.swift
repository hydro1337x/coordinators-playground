//
//  AccountRootScreen.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.06.2025..
//

import SwiftUI

struct AccountRootScreen: View {
    @ObservedObject var store: AccountRootStore
    
    var body: some View {
        Form {
            Section {
                Button("Account Details") {
                    store.handleDetailsButtonTapped()
                }
                
                Button("Help") {
                    store.handleHelpButtonTapped()
                }
            }
            
            Section {
                Button("Logout") {
                    Task { await store.handleLogoutButtonTapped() }
                }
            }
        }
        .overlay {
            VStack {
                Spacer()
                
                VStack {
                    Text("Account registration not completed.")
                        .padding()
                }
                .frame(height: 50)
                .background(.red)
                .cornerRadius(8)
            }
        }
    }
}

@MainActor
class AccountRootStore: ObservableObject {
    private let logoutService: LogoutService
    
    var onDetailsButtonTapped: () -> Void = unimplemented()
    var onHelpButtonTapped: () -> Void = unimplemented()
    var onLogoutFinished: () -> Void = unimplemented()
    
    init(logoutService: LogoutService) {
        self.logoutService = logoutService
    }
    
    func handleDetailsButtonTapped() {
        onDetailsButtonTapped()
    }
    
    func handleHelpButtonTapped() {
        onHelpButtonTapped()
    }
    
    func handleLogoutButtonTapped() async {
        await logoutService.logout()
        
        onLogoutFinished()
    }
}
