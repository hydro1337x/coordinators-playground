//
//  HomeScreenB.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import SwiftUI

struct HomeScreenB: View {
    @ObservedObject var store: HomeStoreB
    
    var body: some View {
        VStack {
            Text(store.title)
            Button(action: {
                store.onPushClone(store.id + 1)
            }) {
                Text("Push Clone")
            }
            Button(action: store.onPushNext) {
                Text("Push C")
            }
        }
    }
}

@MainActor
class HomeStoreB: ObservableObject {
    let title: String
    let id: Int
    var onPushClone: (Int) -> Void = { _ in }
    var onPushNext: () -> Void = unimplemented()
    
    init(id: Int) {
        self.id = id
        self.title = "ScreenB \(id)"
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
}
