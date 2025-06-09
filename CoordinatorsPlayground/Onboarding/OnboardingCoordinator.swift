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
        TabView(selection: .binding(state: { store.tab }, with: store.handleTabChanged)) {
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

@MainActor
class OnboardingCoordinatorStore: ObservableObject, TabNavigationObservable {
    enum Tab: Hashable {
        case screenA
        case screenB
    }
    
    @Published private(set) var tab: Tab = .screenA
    
    private(set) var tabFeatures: [Tab : Feature] = [:]
    
    var onFinished: () -> Void = unimplemented()
    
    func handleTabChanged(_ tab: Tab) {
        self.tab = tab
    }
    
    func handleSkipButtonTapped() {
        onFinished()
    }
}
