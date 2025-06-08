//
//  NavigationTests.swift
//  CoordinatorsPlaygroundTests
//
//  Created by Benjamin Macanovic on 07.06.2025..
//

import Testing
@testable import CoordinatorsPlayground
import SwiftUI

@MainActor
struct NavigationTests {
    let dependendencies = Dependencies()

    @Test func navigation() async throws {
        let rootStore = dependendencies.makeRootCoordinator().cast(to: RootCoordinatorStore.self)!
        let tabsStore = rootStore.tabsCoordinator!.cast(to: TabsCoordinatorStore.self)!
        tabsStore.handleTabChanged(.home)
        let homeStore = tabsStore.tabFeatures[tabsStore.tab]!.cast(to: HomeCoordinatorStore.self)!
        let rootFeatureStore = homeStore.rootFeature!.cast(to: HomeScreenStore.self)!
        rootFeatureStore.onButtonTap()
        homeStore.handleAccountButtonTapped()
        let accountStore = rootStore.destinationFeature!.cast(to: AccountCoordinatorStore.self)!
        accountStore.handleShowDetailsButtonTapped()
        
        #expect(rootStore.sheet == .account)
        #expect(tabsStore.tab == .home)
        #expect(homeStore.path == [.screenA])
        #expect(accountStore.path == [.details])
    }

}
