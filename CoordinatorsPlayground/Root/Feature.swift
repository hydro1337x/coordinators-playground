//
//  Feature.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 24.05.2025..
//

import Foundation
import SwiftUI

struct Feature: View {
    private let _view: AnyView
    private let _store: AnyObject
    
    let underlyingView: Any
    
    init<V: View, S: AnyObject>(view: V, store: S) {
        self._view = AnyView(view)
        self._store = store
        self.underlyingView = view
    }
    
    var body: some View {
        _view
    }
    
    func `as`<T>(type: T.Type) -> T? {
        _store as? T
    }
}

