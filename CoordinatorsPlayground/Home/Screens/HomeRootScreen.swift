//
//  HomeRootScreen.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import SwiftUI

struct HomeRootScreen: View {
    @Environment(\.theme) var theme: Theme
    @ObservedObject var store: HomeRootStore
    
    var body: some View {
        VStack {
            Text(store.title)
            Button(action: store.onButtonTap) {
                Text("Push A")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .bottom)
        .background(theme.background)
    }
}

@MainActor
class HomeRootStore: ObservableObject {
    let title: String = "Home"
    var onButtonTap: () -> Void = unimplemented()
}
