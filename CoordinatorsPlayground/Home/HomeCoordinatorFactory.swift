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
