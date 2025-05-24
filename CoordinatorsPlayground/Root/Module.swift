//
//  Module.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 24.05.2025..
//

import Foundation
import SwiftUI

struct Feature: View {
    private let _view: AnyView
    private let _store: AnyObject
    
    init<V: View>(view: V, store: AnyObject) {
        self._view = AnyView(view)
        self._store = store
    }
    
    var body: some View {
        _view
    }
    
    func asRouter() -> Router? {
        _store as? Router
    }
}
