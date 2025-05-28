//
//  TabsCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import SwiftUI

struct TabsCoordinator: View {
    @ObservedObject var store: TabsCoordinatorStore
    
    var body: some View {
        TabView(selection: .init(get: { store.tab }, set: { store.handleTabChanged($0) })) {
            if let tabFeature = store.tabFeatures[.home] {
                tabFeature
                    .tag(TabsCoordinatorStore.Tab.home)
                    .tabItem {
                        Image(systemName: "list.bullet")
                    }
            }
            
            Text("Second Tab View")
                .tag(TabsCoordinatorStore.Tab.second)
                .tabItem {
                    Image(systemName: "paperplane")
                }
        }
    }
}

@MainActor
class TabsCoordinatorStore: ObservableObject {
    enum Tab: CaseIterable, Codable {
        case home
        case second
    }
    
    @Published var tab: Tab
    private(set) var tabFeatures: [Tab: Feature] = [:]
    private var routingHandlers: [(Route) async -> Void] = []
    
    var onAccountButtonTapped: () -> Void = unimplemented()
    var onLoginButtonTapped: () -> Void = unimplemented()
    
    private let factory: TabsCoordinatorFactory
    let router: any Router<TabsStep>
    
    init(selectedTab: Tab, factory: TabsCoordinatorFactory, router: any Router<TabsStep>) {
        self.factory = factory
        self.router = router
        self.tab = selectedTab
        
        Tab.allCases.forEach { makeFeature(for: $0) }
        
        router.setup(using: self, childRoutables: { [weak self] in
            guard let self else { return [] }
            return self.tabFeatures.values.compactMap { $0.as(type: (any Routable).self) }
        })
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
    
    private func makeFeature(for tab: Tab) {
        switch tab {
        case .home:
            let feature = factory.makeHomeCoordinator(
                onAccountButtonTapped: { [weak self] in
                    self?.onAccountButtonTapped()
                },
                onLoginButtonTapped: { [weak self] in
                    self?.onLoginButtonTapped()
                }
            )
            tabFeatures[tab] = feature
        case .second:
            break
        }
    }
    
    func handleTabChanged(_ tab: Tab) {
        self.tab = tab
    }
    
    private func show(tab: Tab) {
        self.tab = tab
    }
}

extension TabsCoordinatorStore: Routable {
    func handle(step: TabsStep) async {
        switch step {
        case .tab(let tab):
            switch tab {
            case .home:
                show(tab: .home)
            case .profile:
                show(tab: .second)
            }
        }
    }
}

struct TabsState: Codable {
    let tab: TabsCoordinatorStore.Tab
}

extension TabsCoordinatorStore: StateRestoring {
    func saveState() throws -> [Data] {
        let state = TabsState(tab: tab)
        return [try encode(state)]
    }
    
    func restoreState(from data: [Data]) throws {
        guard let first = data.first else { return }
        
        let state = try decode(first, as: TabsState.self)
        
        self.tab = state.tab
    }
}

enum TabsStep: Decodable {
    enum Tab: String, Decodable {
        case home
        case profile
    }
    
    case tab(Tab)

    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    private enum StepType: String, Decodable {
        case tab
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StepType.self, forKey: .type)

        switch type {
        case .tab:
            let tab = try container.decode(Tab.self, forKey: .value)
            self = .tab(tab)
        }
    }
}
