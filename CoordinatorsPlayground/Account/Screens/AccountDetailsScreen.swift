//
//  AccountDetailsScreen.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 20.05.2025..
//

import SwiftUI

struct AccountDetailsScreen: View {
    @ObservedObject var store: AccountDetailsStore
    
    var body: some View {
        Text(store.title)
    }
}

class AccountDetailsStore: ObservableObject {
    let title = "Account Details"
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
}
