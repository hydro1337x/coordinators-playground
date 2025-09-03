//
//  FeedbackMessage.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 17.06.2025..
//

import Foundation

enum FeedbackMessageIntent: Int, Comparable {
    case info = 0
    case success = 1
    case warning = 2
    case failure = 3
    
    static func < (lhs: FeedbackMessageIntent, rhs: FeedbackMessageIntent) -> Bool {
        lhs.rawValue < rhs.rawValue
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
