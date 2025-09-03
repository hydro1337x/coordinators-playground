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

#Preview {
    Container()
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
