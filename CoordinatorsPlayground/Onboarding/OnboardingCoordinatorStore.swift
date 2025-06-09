//
//  OnboardingCoordinatorStore.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 09.06.2025..
//

import Foundation

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
