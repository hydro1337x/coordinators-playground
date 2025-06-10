//
//  SearchCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import SwiftUI

struct SearchCoordinator: View {
    @ObservedObject var store: SearchCoordinatorStore
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            TabView(selection: .binding(state: { store.tab }, with: store.handleTabChanged)) {
                Group {
                    ImageFeedScreen()
                        .tag(SearchCoordinatorStore.Tab.imageFeed)

                    VideoFeedScreen()
                        .tag(SearchCoordinatorStore.Tab.videoFeed)
                }
            }
            .navigationTitle("Search")
            .toolbar(content: leadingToolbarGroup)
            .toolbar(content: trailingToolbarGroup)
        }
        .searchable(text: $searchText)
        .task(store.bindObservers)
    }
    
    func leadingToolbarGroup() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Menu {
                Picker("", selection: .binding(state: { store.tab }, with: { store.handleTabChanged($0) })) {
                    Text("Image").tag(SearchCoordinatorStore.Tab.imageFeed)
                    Text("Video").tag(SearchCoordinatorStore.Tab.videoFeed)
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
            }

        }
    }
    
    func trailingToolbarGroup() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            HStack {
                switch store.authState {
                case .loggedIn:
                    Button("Account") {
                        store.handleAccountButtonTapped()
                    }
                case .loginInProgress:
                    ProgressView()
                        .progressViewStyle(.circular)
                case .loggedOut:
                    Button("Login") {
                        store.handleLoginButtonTapped()
                    }
                case nil:
                    EmptyView()
                }
            }
        }
    }
}
