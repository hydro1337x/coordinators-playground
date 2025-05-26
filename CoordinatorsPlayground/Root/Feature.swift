//
//  Feature.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 24.05.2025..
//

import Foundation
import SwiftUI

struct _Feature<V: View, S: AnyObject>: View {
    let _view: V
    let _store: S
    
    private init(view: V, store: S) {
        self._view = view
        self._store = store
    }
    
    var body: some View {
        _view
    }
}

extension _Feature: Router where S: Router {
    typealias Step = S.Step
    
    var childRouters: [any Router] {
        _store.childRouters
    }
    
    var onUnhandledRoute: (Route) async -> Bool {
        _store.onUnhandledRoute
    }
    
    func handle(step: Step) async -> Bool {
        await _store.handle(step: step)
    }
}

fileprivate extension _Feature {
    static func makeFeature(view: V, store: S) -> _Feature {
        .init(view: view, store: store)
    }
}

struct Feature: View {
    private let _view: AnyView
    private let _store: AnyObject
    
    let underlyingFeature: Any
    
    init<V: View, S: AnyObject>(view: V, store: S) {
        self._view = AnyView(view)
        self._store = store
        let feature = _Feature.makeFeature(view: view, store: store)
        self.underlyingFeature = feature
    }
    
    var body: some View {
        _view
    }
    
    func `as`<T>(type: T.Type) -> T? {
        _store as? T
    }
}

