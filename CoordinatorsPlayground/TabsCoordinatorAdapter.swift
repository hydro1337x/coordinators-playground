//
//  TabsCoordinatorAdapter.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 15.06.2025..
//

import Foundation
import Combine

final class TabsCoordinatorAdapter {
    let activeTabs: [Tab] = [.home, .search, .settings]
    var onHideTabBar: () -> Void = unimplemented()
    var onShowTabBar: () -> Void = unimplemented()
    var onActiveTabsChanged: ([Tab]) -> Void = unimplemented()
    
    private var cancellables: Set<AnyCancellable> = []
    
    func subscribe(to tabsPublisher: Published<[Tab]>.Publisher) {
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
