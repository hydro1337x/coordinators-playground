//
//  OnboardingCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 14.05.2025..
//

import SwiftUI

struct OnboardingCoordinator: View {
    @ObservedObject var store: OnboardingCoordinatorStore
    
    var body: some View {
        TabView(
            selection: Binding(
                get: { store.tab },
                set: { store.handleTabChanged($0) }
            )
        ) {
            OnboardingScreenA()
                .tag(OnboardingCoordinatorStore.Tab.screenA)

            OnboardingScreenB()
                .tag(OnboardingCoordinatorStore.Tab.screenB)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .overlay {
            VStack(alignment: .trailing) {
                HStack(alignment: .top) {
                    Spacer()
                    Button("Skip") {
                        store.handleSkipButtonTapped()
                    }
                }
                Spacer()
            }
        }
    }
}


