//
//  FloatingStack.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 31.05.2025..
//

import SwiftUI

struct FloatingStack: View {
    @Environment(\.theme) var theme
    @ObservedObject var store: FloatingStackStore
    
    var body: some View {
        VStack {
            Spacer()
            ForEach(store.queue) { message in
                switch message {
                case .basic(let message):
                    Toast(
                        color: message.intent.color(for: theme),
                        message: message.description
                    )
                case .action(let action):
                    Text("Action \(action)")
                }
            }
        }
        .padding(.bottom, store.dynamicPadding)
        .padding(.bottom, 8)
        .animation(.default, value: store.queue)
    }
}

private struct Container: View {
    var body: some View {
        VStack {
            Toast(color: .blue, message: "Toast Message")
        }
    }
}

extension FeedbackMessageIntent {
    func color(for theme: Theme) -> Color {
        switch self {
        case .info:
            theme.info
        case .success:
            theme.success
        case .warning:
            theme.warning
        case .failure:
            theme.failure
        }
    }
}

#Preview {
    Container()
}

enum FeedbackMessageIntent: Int, Comparable {
    case info = 0
    case success = 1
    case warning = 2
    case failure = 3
    
    static func < (lhs: FeedbackMessageIntent, rhs: FeedbackMessageIntent) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

protocol FeedbackMessageSending {
    var onFeedbackMessage: (FeedbackMessage) -> Void { get }
}

enum FeedbackMessage: Identifiable, Equatable {
    case basic(BasicFeedbackMessage)
    case action(ActionFeedbackMessage)
    
    var id: UUID {
        switch self {
        case .basic(let message):
            return message.id
        case .action(let message):
            return message.id
        }
    }
    
    var createdAt: Date {
        switch self {
        case .basic(let message):
            return message.createdAt
        case .action(let message):
            return message.createdAt
        }
    }
    
    var intent: FeedbackMessageIntent {
        switch self {
        case .basic(let message):
            return message.intent
        case .action(let message):
            return message.intent
        }
    }
    
    var duration: Duration {
        switch self {
        case .basic(let message):
            return message.duration
        case .action(let message):
            return message.duration
        }
    }
}

struct BasicFeedbackMessage: Equatable {
    let id = UUID()
    let description: String
    let intent: FeedbackMessageIntent
    let createdAt = Date()
    let duration = Duration.seconds(4)
}

struct ActionFeedbackMessage: Equatable {
    let id = UUID()
    let description: String
    let intent: FeedbackMessageIntent
    let createdAt = Date()
    let action: () -> Void
    let duration = Duration.seconds(6)
    
    static func == (lhs: ActionFeedbackMessage, rhs: ActionFeedbackMessage) -> Bool {
        lhs.id == rhs.id
    }
}

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
        
        simulateSequence()
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
