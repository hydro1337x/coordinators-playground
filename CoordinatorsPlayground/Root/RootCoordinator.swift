//
//  RootCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import SwiftUI

struct RootCoordinator: View {
    @ObservedObject var store: RootCoordinatorStore
    
    var body: some View {
        if let tabsCoordinator = store.flowFeatures[.tabs] {
            tabsCoordinator
                .sheet(item: .binding(
                    state: { store.destination?.sheet },
                    with: store.handleSheetChanged)
                ) { sheet in
                    switch sheet {
                    case .auth:
                        makeDestinationFeature()
                    case .account:
                        makeDestinationFeature()
                    }
                }
                .fullScreenCover(item: .binding(
                    state: { store.destination?.fullscreenCover },
                    with: store.handleFullscreenCoverChanged)
                ) { destination in
                    switch destination {
                    case .onboarding:
                        makeDestinationFeature()
                    }
                }
        } else {
            Text("Something went wrong")
        }
    }
    
    @ViewBuilder
    func makeDestinationFeature() -> some View {
        if let view = store.destinationFeature {
            view
        } else {
            Text("Something went wrong")
        }
    }
}


