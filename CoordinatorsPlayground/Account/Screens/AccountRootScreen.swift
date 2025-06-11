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
            
            Section("Theme") {
                Picker(
                    selection: Binding(
                        get: { store.theme },
                        set: { store.handleThemeChanged($0) }
                    ),
                    content: {
                        Text("Light")
                            .tag(Theme.light)
                        Text("Dark")
                            .tag(Theme.dark)
                    },
                    label: {
                        Text("Selected")
                    }
                )
                .pickerStyle(.menu)
            }
            
            Section {
                Button("Logout") {
                    Task { await store.handleLogoutButtonTapped() }
                }
            }
        }
        .onAppear(perform: store.handleOnAppear)
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
    @Published private(set) var theme: Theme = .light
    
    private let logoutService: LogoutService
    private let themeService: SetThemeService & GetThemeService
    
    var onDetailsButtonTapped: () -> Void = unimplemented()
    var onHelpButtonTapped: () -> Void = unimplemented()
    var onLogoutFinished: () -> Void = unimplemented()
    
    init(
        logoutService: LogoutService,
        themeService: SetThemeService & GetThemeService
    ) {
        self.logoutService = logoutService
        self.themeService = themeService
    }
    
    func handleOnAppear() {
        Task {
            if let currentTheme = await themeService.getTheme() {
                self.theme = currentTheme
            }
        }
    }
    
    func handleThemeChanged(_ theme: Theme) {
        self.theme = theme
        
        Task {
            switch theme {
            case .light:
                await handleLightThemeButtonTapped()
            case .dark:
                await handleDarkThemeButtonTapped()
            }
        }
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
