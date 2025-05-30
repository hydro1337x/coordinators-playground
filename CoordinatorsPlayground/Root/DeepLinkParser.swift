//
//  DeepLinkParser.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import Foundation

enum DeepLinkParser {
    static func parse(_ url: URL) -> Route? {
        guard
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            urlComponents.host == "deeplink",
            let queryItems = urlComponents.queryItems,
            let payload = queryItems.first(where: { $0.name == "payload" })?.value,
            let data = Data(base64Encoded: payload)
        else {
            print("Invalid DeepLink payload")
            return nil
        }
        
        let route: Route?
        
        do {
            route = try JSONDecoder().decode(Route.self, from: data)
        } catch {
            route = nil
            print("Decoding DeepLink failed: \(error)")
        }
        
        return route
    }
}

struct Route: Decodable {
    let step: Data
    let children: [Route]

    enum CodingKeys: String, CodingKey {
        case step
        case children
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode step into an opaque Swift structure (unknown contents)
        let stepDecoder = try container.superDecoder(forKey: .step)

        // Re-encode that structure into raw Data
        let stepValue = try JSONValue(from: stepDecoder)
        self.step = try JSONEncoder().encode(stepValue)

        self.children = try container.decodeIfPresent([Route].self, forKey: .children) ?? []
    }
}

enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case object([String: JSONValue])
    case array([JSONValue])
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let n = try? container.decode(Double.self) {
            self = .number(n)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let a = try? container.decode([JSONValue].self) {
            self = .array(a)
        } else if let o = try? container.decode([String: JSONValue].self) {
            self = .object(o)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let s): try container.encode(s)
        case .number(let n): try container.encode(n)
        case .bool(let b): try container.encode(b)
        case .object(let o): try container.encode(o)
        case .array(let a): try container.encode(a)
        case .null: try container.encodeNil()
        }
    }
}
