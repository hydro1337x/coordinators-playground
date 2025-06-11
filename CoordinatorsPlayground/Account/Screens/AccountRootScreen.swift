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
        VStack {
            Text("User Bob Account")
            VStack {
                Button("Push Details") {
                    store.handleDetailsButtonTapped()
                }
                Button("Present Help") {
                    store.handleHelpButtonTapped()
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
            Button("Logout") {
                Task { await store.handleLogoutButtonTapped() }
            }
            
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

@MainActor
class AccountRootStore: ObservableObject {
    private let logoutService: LogoutService
    private let themeService: SetThemeService
    
    var onDetailsButtonTapped: () -> Void = unimplemented()
    var onHelpButtonTapped: () -> Void = unimplemented()
    var onLogoutFinished: () -> Void = unimplemented()
    
    init(logoutService: LogoutService, themeService: SetThemeService) {
        self.logoutService = logoutService
        self.themeService = themeService
    }
    
    func handleDetailsButtonTapped() {
        onDetailsButtonTapped()
    }
    
    func handleHelpButtonTapped() {
        onHelpButtonTapped()
    }
    
    func handleLightThemeButtonTapped() async {
        await themeService.set(theme: .light)
    }
    
    func handleDarkThemeButtonTapped() async {
        await themeService.set(theme: .dark)
    }
    
    func handleLogoutButtonTapped() async {
        await logoutService.logout()
        
        onLogoutFinished()
    }
}
