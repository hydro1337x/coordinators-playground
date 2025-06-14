//
//  SettingsCoordinator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 14.06.2025..
//

import SwiftUI

struct SettingsCoordinator: View {
    @ObservedObject var store: SettingsCoordinatorStore
    
    var body: some View {
        NavigationStack {
            store.rootFeature
                .navigationTitle("Settings")
        }
    }
}
