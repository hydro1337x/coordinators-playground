//
//  SpecialFlowCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 15.06.2025..
//

import SwiftUI

struct SpecialFlowCoordinator: View {
    var store: SpecialFlowCoordinatorStore
    
    var body: some View {
        NavigationStack {
            VStack {
                Button("Back to main flow") {
                    store.handleMainFlowButtonTapped()
                }
            }
            .navigationTitle("Speacial Flow")
        }
    }
}

class SpecialFlowCoordinatorStore: ObservableObject {
    var onMainFlowButtonTapped: () -> Void = unimplemented()
    
    func handleMainFlowButtonTapped() {
        onMainFlowButtonTapped()
    }
}
