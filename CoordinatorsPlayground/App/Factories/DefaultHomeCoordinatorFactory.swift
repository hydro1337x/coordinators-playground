//
//  DefaultHomeCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 17.06.2025..
//

import Foundation

struct DefaultHomeCoordinatorFactory: HomeCoordinatorFactory {
    let mainTabsCoordinatorAdapter: MainTabsCoordinatorAdapter
    
    func makeRootScreen(onButtonTap: @escaping () -> Void) -> Feature {
        let store = HomeRootStore()
        store.onButtonTap = onButtonTap
        let view = HomeRootScreen(store: store).navigationTitle(store.title)
        return Feature(view: view, store: store)
    }
    func makeScreenA(onButtonTap: @escaping () -> Void) -> Feature {
        let store = HomeStoreA()
        store.onButtonTap = onButtonTap
        let view = HomeScreenA(store: store).navigationTitle(store.title)
        return Feature(view: view, store: store)
    }
    
    func makeScreenB(id: Int, onPushClone: @escaping (Int) -> Void, onPushNext: @escaping () -> Void) -> Feature {
        let store = HomeStoreB(id: id)
        store.onPushClone = onPushClone
        store.onPushNext = onPushNext
        let view = HomeScreenB(store: store).navigationTitle(store.title)
        return Feature(view: view, store: store)
    }
    
    func makeScreenC(onBackButtonTapped: @escaping () -> Void) -> Feature {
        let store = HomeStoreC()
        store.onBack = onBackButtonTapped
        let view = HomeScreenC(store: store).navigationTitle(store.title)
        return Feature(view: view, store: store)
    }
}
