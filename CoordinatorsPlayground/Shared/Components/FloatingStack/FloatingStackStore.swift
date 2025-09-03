//
//  FloatingStackStore.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 17.06.2025..
//

import Foundation
import Combine

@MainActor
final class FloatingStackStore: ObservableObject {
    @Published private(set) var queue: [FeedbackMessage] = []
    @Published private(set) var dynamicPadding: CGFloat = 0
    
    private let clock: any Clock<Duration>
    
    init(clock: any Clock<Duration>, topVisibleState: AnyPublisher<AnyHashable?, Never>) {
        self.clock = clock
        
        topVisibleState
            .map {
                if let destination = $0 as? RootCoordinatorStore.Destination, destination == .sheet(.account) {
                    return Double(50)
                } else {
                    return Double(0)
                }
            }
            .assign(to: &$dynamicPadding)
        
//        simulateSequence()
    }
    
    func enqueue(message: FeedbackMessage) {
        queue.append(message)
        queue.sort { $0.intent > $1.intent }
        
        Task {
            try await clock.sleep(for: message.duration)
            queue.removeAll(where: { $0.id == message.id })
        }
    }
    
    func simulateSequence() {
        Task {
            while true {
                let info = BasicFeedbackMessage(description: "Some Info", intent: .info)
                let success = BasicFeedbackMessage(description: "Some Success", intent: .success)
                let warning = BasicFeedbackMessage(description: "Some Warning", intent: .warning)
                let error = BasicFeedbackMessage(description: "Some Error", intent: .failure)
                
                let items = [info, success, warning, error]
                
                let i = Int.random(in: 0...3)
                let item = items[i]
                try await Task.sleep(for: .seconds(i + 1))
                enqueue(message: .basic(item))
            }
        }
    }
}
