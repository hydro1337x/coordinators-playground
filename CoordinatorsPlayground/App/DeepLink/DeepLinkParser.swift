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
