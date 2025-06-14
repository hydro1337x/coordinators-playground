//
//  SettingsRootScreen.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 14.06.2025..
//

import SwiftUI

struct SettingsRootScreen: View {
    @ObservedObject var store: SettingsRootStore
    
    var body: some View {
        Form {
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
            
            Section("Tab order") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.activeTabs, id: \.self) { tab in
                            Button(action: {
                                print("Tapped on \(tab)")
                                store.handleTabSelected(tab)
                            }) {
                                Text(tab.title)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .animation(.default, value: store.activeTabs)
                    }
                    .padding(.vertical, 4)
                }
                
                if let selectedTab = store.selectedTab {
                    Picker(
                        selection: Binding(
                            get: { store.selectedTabOrder },
                            set: { store.handleTabOrderChanged($0) }
                        ),
                        content: {
                            ForEach(Array(store.activeTabs.indices), id: \.self) { index in
                                Text(index.description)
                                    .tag(index)
                            }
                        },
                        label: {
                            Text("\(selectedTab.title) order")
                        }
                    )
                    .pickerStyle(.menu)
                }
            }
        }
        .onAppear(perform: store.handleOnAppear)
    }
}

@MainActor
class SettingsRootStore: ObservableObject {
    @Published private(set) var activeTabs: [Tab] {
        didSet {
            onTabsChanged(activeTabs)
        }
    }
    @Published private(set) var selectedTab: Tab?
    @Published private(set) var selectedTabOrder: Int = 0
    @Published private(set) var theme: Theme = .light
    
    var onTabsChanged: ([Tab]) -> Void = unimplemented()
    
    private let themeService: SetThemeService & GetThemeService
    
    init(activeTabs: [Tab], themeService: SetThemeService & GetThemeService) {
        self.activeTabs = activeTabs
        self.themeService = themeService
    }
    
    func handleOnAppear() {
        Task {
            if let currentTheme = await themeService.getTheme() {
                self.theme = currentTheme
            }
        }
    }
    
    func handleTabSelected(_ tab: Tab) {
        selectedTab = tab
        if let selectedTabOrder = activeTabs.firstIndex(of: tab) {
            self.selectedTabOrder = selectedTabOrder
        }
    }
    
    func handleTabOrderChanged(_ selectedTabOrder: Int) {
        self.selectedTabOrder = selectedTabOrder
        
        if let selectedTab {
            activeTabs.removeAll(where: { $0 == selectedTab })
            activeTabs.insert(selectedTab, at: selectedTabOrder)
        }
        
        selectedTab = nil
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
    
    func handleLightThemeButtonTapped() async {
        await themeService.set(theme: .light)
    }
    
    func handleDarkThemeButtonTapped() async {
        await themeService.set(theme: .dark)
    }
}

private extension Tab {
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .search:
            return "Search"
        case .settings:
            return "Settings"
        }
    }
}
