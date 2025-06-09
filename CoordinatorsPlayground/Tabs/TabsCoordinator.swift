//
//  TabsCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import SwiftUI

struct TabsCoordinator: View {
    @ObservedObject var store: TabsCoordinatorStore
    var makeFloatingStack: () -> AnyView
    
    var body: some View {
        TabView(selection: .binding(
            state: { store.tab },
            with: store.handleTabChanged)
        ) {
            Group {
                if let tabFeature = store.tabFeatures[.home] {
                    tabFeature
                        .tag(TabsCoordinatorStore.Tab.home)
                        .tabItem {
                            Image(systemName: "list.bullet")
                        }
                }
                
                ProfileScreen()
                    .tag(TabsCoordinatorStore.Tab.second)
                    .tabItem {
                        Image(systemName: "paperplane")
                    }
            }
            .overlay {
                makeFloatingStack()
                    .transaction { transaction in
                        // Explicitly animating change of safeAreaInset with GeometryReader causes wierd flickering
                        // This is a workaround for .animation(.default) which is deprecated
                        transaction.animation = .default
                    }
            }
            .toolbar(store.isTabBarVisible ? .visible : .hidden, for: .tabBar)
            .toolbarBackground(.white, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .animation(.default, value: store.isTabBarVisible)
        }
    }
}


