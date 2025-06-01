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
    func makeHomeScreen(onButtonTap: @escaping () -> Void) -> Feature
    func makeScreenA(onButtonTap: @escaping () -> Void) -> Feature
    func makeScreenB(id: Int, onPushClone: @escaping (Int) -> Void, onPushNext: @escaping () -> Void) -> Feature
    func makeScreenC(onBackButtonTapped: @escaping () -> Void) -> Feature
}

struct DefaultHomeCoordinatorFactory: HomeCoordinatorFactory {
    let tabsCoordinatorAdapter: TabsCoordinatorAdapter
    
    func makeHomeScreen(onButtonTap: @escaping () -> Void) -> Feature {
        let store = HomeScreenStore()
        store.onButtonTap = {
            onButtonTap()
            tabsCoordinatorAdapter.onScreenAPushed()
        }
        let view = HomeScreen(store: store).navigationTitle(store.title)
        return Feature(view: view, store: store)
    }
    func makeScreenA(onButtonTap: @escaping () -> Void) -> Feature {
        let store = StoreA()
        store.onButtonTap = onButtonTap
        let view = ScreenA(store: store).navigationTitle(store.title)
        return Feature(view: view, store: store)
    }
    
    func makeScreenB(id: Int, onPushClone: @escaping (Int) -> Void, onPushNext: @escaping () -> Void) -> Feature {
        let store = StoreB(id: id)
        store.onPushClone = onPushClone
        store.onPushNext = onPushNext
        let view = ScreenB(store: store).navigationTitle(store.title)
        return Feature(view: view, store: store)
    }
    
    func makeScreenC(onBackButtonTapped: @escaping () -> Void) -> Feature {
        let store = StoreC()
        store.onBack = onBackButtonTapped
        let view = ScreenC(store: store).navigationTitle(store.title)
        return Feature(view: view, store: store)
    }
}
