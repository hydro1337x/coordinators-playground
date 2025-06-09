//
//  HomeScreenA.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import SwiftUI

struct HomeScreenA: View {
    @ObservedObject var store: HomeStoreA
    
    var body: some View {
        VStack {
            Text(store.title)
            Button(action: store.onButtonTap) {
                Text("Push B")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .bottom)
        .background(.red)
    }
}

@MainActor
class HomeStoreA: ObservableObject {
    let title: String = "ScreenA"
    var onButtonTap: () -> Void = unimplemented()
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
}
