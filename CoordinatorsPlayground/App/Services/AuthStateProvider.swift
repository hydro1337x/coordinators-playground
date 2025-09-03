//
//  AuthStateProvider.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 22.05.2025..
//

import Foundation

actor AuthStateProvider: AuthStateValueService, AuthStateStreamService, SetAuthStateService {
    private struct Subscriber {
        let id: UUID
        let continuation: AsyncStream<AuthState>.Continuation
    }
    
    private var state: AuthState = .loggedOut
    private var subscribers: [Subscriber] = []
    
    var currentValue: AuthState {
        state
    }
    
    var values: AsyncStream<AuthState> {
        let id = UUID()
        
        return AsyncStream { continuation in
            // Yield the current value immediately
            continuation.yield(state)
            
            let subscriber = Subscriber(id: id, continuation: continuation)
            subscribers.append(subscriber)
            
            continuation.onTermination = { [weak self] _ in
                Task {
                    await self?.removeSubscribers(where: id)
                }
            }
        }
    }
    
    func setState(_ newState: AuthState) {
        guard newState != state else { return }
        state = newState
        for subscriber in subscribers {
            subscriber.continuation.yield(newState)
        }
    }
    
    private func removeSubscribers(where id: UUID) {
        print("Removing subscribers for \(id)")
        subscribers.removeAll { $0.id == id }
    }
}
