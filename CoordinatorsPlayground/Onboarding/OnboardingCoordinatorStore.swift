//
//  OnboardingCoordinatorStore.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import Foundation

@MainActor
class OnboardingCoordinatorStore: ObservableObject, TabsCoordinator {
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

extension OnboardingCoordinatorStore {
    enum Tab: Hashable {
        case screenA
        case screenB
    }
}
