//
//  DefaultHomeCoordinatorFactory.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 23.05.2025..
//

import Foundation
import SwiftUI

@MainActor
protocol HomeCoordinatorFactory {
    func makeRootScreen(onButtonTap: @escaping () -> Void) -> Feature
    func makeScreenA(onButtonTap: @escaping () -> Void) -> Feature
    func makeScreenB(id: Int, onPushClone: @escaping (Int) -> Void, onPushNext: @escaping () -> Void) -> Feature
    func makeScreenC(onBackButtonTapped: @escaping () -> Void) -> Feature
}

struct DefaultHomeCoordinatorFactory: HomeCoordinatorFactory {
    let tabsCoordinatorAdapter: TabsCoordinatorAdapter
    
    func makeRootScreen(onButtonTap: @escaping () -> Void) -> Feature {
        let store = HomeRootStore()
        store.onButtonTap = {
            onButtonTap()
            tabsCoordinatorAdapter.onScreenAPushed()
        }
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
