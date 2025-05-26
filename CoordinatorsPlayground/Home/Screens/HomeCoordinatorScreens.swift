//
//  StackCoordinatorScreens.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import SwiftUI

// MARK: - Root Screen

struct HomeScreen: View {
    @Environment(\.theme) var theme: Theme
    @ObservedObject var store: HomeScreenStore
    
    var body: some View {
        VStack {
            Text(store.title)
            Button(action: store.onButtonTap) {
                Text("Push A")
            }
        }
        .background(theme.background)
    }
}

@MainActor
class HomeScreenStore: ObservableObject {
    let title: String = "Home"
    var onButtonTap: () -> Void = unimplemented()
}

// MARK: - ScreenA
struct ScreenA: View {
    @ObservedObject var store: StoreA
    
    var body: some View {
        VStack {
            Text(store.title)
            Button(action: store.onButtonTap) {
                Text("Push B")
            }
        }
    }
}

@MainActor
class StoreA: ObservableObject {
    let title: String = "ScreenA"
    var onButtonTap: () -> Void = unimplemented()
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
}

// MARK: - ScreenB

struct ScreenB: View {
    @ObservedObject var store: StoreB
    
    var body: some View {
        VStack {
            Text(store.title)
            Button(action: {
                store.onPushClone(store.id + 1)
            }) {
                Text("Push Clone")
            }
            Button(action: store.onPushNext) {
                Text("Push C")
            }
        }
    }
}

@MainActor
class StoreB: ObservableObject {
    let title: String
    let id: Int
    var onPushClone: (Int) -> Void = { _ in }
    var onPushNext: () -> Void = unimplemented()
    
    init(id: Int) {
        self.id = id
        self.title = "ScreenB \(id)"
    }
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
}

// MARK: - ScreenC

struct ScreenC: View {
    @ObservedObject var store: StoreC
    
    var body: some View {
        VStack {
            Text(store.title)
            Button(action: store.onBack) {
                Text("Go back")
            }
        }
    }
}

@MainActor
class StoreC: ObservableObject {
    let title: String = "ScreenC"
    var onBack: () -> Void = unimplemented()
    
    deinit {
        print("Deinited: \(String(describing: self))")
    }
}
