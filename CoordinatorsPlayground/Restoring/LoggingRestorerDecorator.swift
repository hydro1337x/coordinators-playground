//
//  LoggingRestorerDecorator.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 28.05.2025..
//

import Foundation

struct LoggingRestorerDecorator<State: Codable>: Restorer {
    private let wrapped: any Restorer<State>
    private let typeName: String

    init(wrapping wrapped: any Restorer<State>) {
        self.wrapped = wrapped
        self.typeName = String(describing: State.self)
    }

    func setup(
        using restorable: any Restorable<State>,
        childRestorables: @escaping () -> [any Restorable]
    ) {
        print("🛠️ [Restorer:\(typeName)] setup called.")
        wrapped.setup(using: restorable, childRestorables: childRestorables)
    }

    func restore(from snapshot: RestorableSnapshot) async -> Bool {
        print("🔄 [Restorer:\(typeName)] Starting restore...")

        let start = CFAbsoluteTimeGetCurrent()
        let success = await wrapped.restore(from: snapshot)

        if !success {
            if let jsonPreview = prettyPrintedJSON(from: snapshot.state) {
                print("⚠️ [Restorer:\(typeName)] Failed to decode state. Snapshot JSON:\n\(jsonPreview)")
            } else {
                print("⚠️ [Restorer:\(typeName)] Failed to decode state. Raw Data: \(snapshot.state)")
            }
        }

        let duration = CFAbsoluteTimeGetCurrent() - start
        print("✅ [Restorer:\(typeName)] Restore finished (success: \(success)) in \(String(format: "%.2f", duration))s")
        return success
    }

    func captureHierarchy() async -> RestorableSnapshot {
        print("📸 [Restorer:\(typeName)] Creating snapshot...")
        let snapshot = await wrapped.captureHierarchy()
        print("✅ [Restorer:\(typeName)] Snapshot created with \(snapshot.children.count) children.")
        return snapshot
    }

    // MARK: - Private

    private func prettyPrintedJSON(from data: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let prettyData = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted),
            let string = String(data: prettyData, encoding: .utf8)
        else {
            return nil
        }

        return string
    }
}
