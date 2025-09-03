//
//  MainTabsCoordinatorAdapter.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 15.06.2025..
//

import Foundation
import Combine

final class MainTabsCoordinatorAdapter {
    let activeTabs: [MainTab] = [.home, .search, .settings]
    var onHideTabBar: () -> Void = unimplemented()
    var onShowTabBar: () -> Void = unimplemented()
    var onActiveTabsChanged: ([MainTab]) -> Void = unimplemented()
    
    private var cancellables: Set<AnyCancellable> = []
    
    func subscribe(to tabsPublisher: Published<[MainTab]>.Publisher) {
        tabsPublisher
            .dropFirst()
            .sink { [weak self] tabs in
                self?.onActiveTabsChanged(tabs)
            }
            .store(in: &cancellables)
    }
    
    func subscribe(to pathPublisher: Published<[HomeCoordinatorStore.Path]>.Publisher) {
        pathPublisher
            .dropFirst()
            .scan(false) { _, path in
                path.contains(.screenA)
            }
            .removeDuplicates()
            .sink { [weak self] isScreenAOnStack in
                if isScreenAOnStack {
                    self?.onHideTabBar()
                } else {
                    self?.onShowTabBar()
                }
            }
            .store(in: &cancellables)
    }
}
