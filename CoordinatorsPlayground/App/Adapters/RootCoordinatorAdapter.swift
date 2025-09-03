//
//  RootCoordinatorAdapter.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 15.06.2025..
//

import Foundation
import Combine

final class RootCoordinatorAdapter {
    var onReachabilityChanged: (Bool) -> Void = unimplemented()
    var onShowSpecialFlow: () -> Void = unimplemented()
    
    private var cancellables: Set<AnyCancellable> = []
    
    func subscribe(to reachabilityPublisher: Published<Bool>.Publisher) {
        reachabilityPublisher
            .dropFirst()
            .sink { [weak self] isReachable in
                self?.onReachabilityChanged(isReachable)
            }
            .store(in: &cancellables)
    }
}
