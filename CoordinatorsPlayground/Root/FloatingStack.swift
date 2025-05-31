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
        .padding(.bottom, 8)
        .padding(.bottom, store.dynamicPadding)
        .animation(.default, value: store.queue)
        .animation(.default, value: store.dynamicPadding)
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
}

struct BasicFeedbackMessage: Equatable {
    let id = UUID()
    let description: String
    let intent: FeedbackMessageIntent
    let createdAt = Date()
}

struct ActionFeedbackMessage: Equatable {
    let id = UUID()
    let description: String
    let intent: FeedbackMessageIntent
    let createdAt = Date()
    let action: () -> Void
    
    static func == (lhs: ActionFeedbackMessage, rhs: ActionFeedbackMessage) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class FloatingStackStore: ObservableObject {
    @Published private(set) var queue: [FeedbackMessage] = []
    @Published private(set) var dynamicPadding: Double = 0
    
    init() {
        simulateSequence()
    }
    
    func enqueue(message: FeedbackMessage) {
        var temp = queue
        temp.append(message)
        
        queue = temp.sorted { lhs, rhs in
            lhs.intent > rhs.intent
        }
    }
    
    func add(padding: Double) {
        dynamicPadding += padding
    }
    
    func subtract(padding: Double) {
        dynamicPadding -= padding
    }
    
    func simulateSequence() {
        let info = BasicFeedbackMessage(description: "Some Info", intent: .info)
        let success = BasicFeedbackMessage(description: "Some Success", intent: .success)
        let warning = BasicFeedbackMessage(description: "Some Warning", intent: .warning)
        let error = BasicFeedbackMessage(description: "Some Error", intent: .failure)
        
        Task {
            try await Task.sleep(for: .seconds(5))
            enqueue(message: .basic(success))
            try await Task.sleep(for: .seconds(2))
            enqueue(message: .basic(info))
            try await Task.sleep(for: .seconds(2))
            enqueue(message: .basic(error))
            try await Task.sleep(for: .seconds(2))
            enqueue(message: .basic(warning))
            try await Task.sleep(for: .seconds(2))
            queue.removeAll()
        }
    }
}
