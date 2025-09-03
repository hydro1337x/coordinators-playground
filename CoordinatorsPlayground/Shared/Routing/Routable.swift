//
//  Routable.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 17.06.2025..
//

import Foundation

@MainActor
protocol Routable<Step>: Coordinator {
    associatedtype Step: Decodable
    
    var router: any Router<Step> { get }
    func handle(step: Step) async
}
