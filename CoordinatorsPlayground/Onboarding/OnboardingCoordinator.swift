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
        TabView {
            OnboardingScreen1()

            OnboardingScreen2()
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

@MainActor
class OnboardingCoordinatorStore: ObservableObject {
    var onFinished: () -> Void = {}
    
    func handleSkipButtonTapped() {
        onFinished()
    }
}
