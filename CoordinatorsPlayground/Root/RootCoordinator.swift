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
        if let mainTabsCoordinator = store.flowFeatures[.tabs] {
            mainTabsCoordinator
                .sheet(
                    item: Binding(
                        get: { store.destination?.sheet },
                        set: { store.handleSheetChanged($0) }
                    )
                ) { sheet in
                    switch sheet {
                    case .auth:
                        makeDestinationFeature()
                    case .account:
                        makeDestinationFeature()
                    }
                }
                .fullScreenCover(
                    item: Binding(
                        get: { store.destination?.fullscreenCover },
                        set: { store.handleFullscreenCoverChanged($0) }
                    )
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


