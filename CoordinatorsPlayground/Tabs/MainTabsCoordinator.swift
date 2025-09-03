//
//  MainTabsCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import SwiftUI

struct MainTabsCoordinator: View {
    @ObservedObject var store: MainTabsCoordinatorStore
    var makeFloatingStack: () -> AnyView
    
    var body: some View {
        TabView(
            selection:
                Binding(
                    get: { store.tab },
                    set: { store.handleTabChanged($0) }
                )
        ) {
            Group {
                ForEach(store.activeTabs, id: \.self) { tab in
                    if let tabFeature = store.tabFeatures[tab] {
                        tabFeature
                            .tag(tab)
                            .tabItem {
                                tab.image
                            }
                    }
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

extension MainTab {
    var image: Image {
        switch self {
        case .home:
            return Image(systemName: "house")
        case .search:
            return Image(systemName: "magnifyingglass")
        case .settings:
            return Image(systemName: "gearshape")
        }
    }
}
