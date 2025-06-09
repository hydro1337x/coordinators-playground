//
//  HomeScreenC.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import SwiftUI

struct HomeScreenC: View {
    @ObservedObject var store: HomeStoreC
    
    var body: some View {
        VStack {
            Text(store.title)
            Button(action: store.onBack) {
                Text("Go back")
            }
        }
    }
}

@MainActor
class HomeStoreC: ObservableObject {
    let title: String = "ScreenC"
    var onBack: () -> Void = unimplemented()
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
}
