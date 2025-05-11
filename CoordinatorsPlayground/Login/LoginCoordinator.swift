//
//  LoginCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import SwiftUI

struct LoginCoordinator: View {
    @ObservedObject var store: LoginCoordinatorStore
    
    var body: some View {
        NavigationStack {
            VStack {
                Button("Login") {
                    store.onFinished()
                }
            }
            .navigationTitle("Login")
        }
    }
}

class LoginCoordinatorStore: ObservableObject {
    var onFinished: () -> Void = {}
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
}
