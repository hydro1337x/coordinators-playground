//
//  RootRouterAdapter.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 15.06.2025..
//

import Foundation

final class RootRouterAdapter {
    var onUnhandledRoute: (Route) async -> Bool = unimplemented(return: false)
}
