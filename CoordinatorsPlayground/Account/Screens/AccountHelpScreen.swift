//
//  AccountHelpScreen.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import SwiftUI

struct AccountHelpScreen: View {
    @ObservedObject var store: AccountHelpStore
    
    var body: some View {
        VStack {
            Spacer()
            Text(store.title)
                .font(.headline)
            Spacer()
            Button("Dismiss", action: store.handleDismissButtonTapped)
        }
    }
}

class AccountHelpStore: ObservableObject {
    let title = "Account Help"
    
    var onDismiss: () -> Void = unimplemented()
    
    func handleDismissButtonTapped() {
        onDismiss()
    }
}
