//
//  DeepLinkParser.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import Foundation

enum DeepLink: Equatable {
    case tabs
    case login
    case home
    case screenA
    case screenB(id: Int)
    case screenC
}

enum DeepLinkParser {
    static func parse(_ url: URL) -> [DeepLink] {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return [] }
        
        var pathComponents = urlComponents.path.split(separator: "/").compactMap(String.init)
        
        if let host = urlComponents.host {
            pathComponents.insert(host, at: 0)
        }
        
        let deeplinks = pathComponents.compactMap { component -> DeepLink? in
            switch component {
            case "tabs":
                return .tabs
            case "login":
                return .login
            case "home":
                return .home
            case "screenA":
                return .screenA
            case "screenB":
                if let value = urlComponents.queryItems?.first(where: { $0.name == "screenBID"})?.value, let id = Int(value) {
                    return .screenB(id: id)
                } else {
                    return nil
                }
            case "screenC":
                return .screenC
            default:
                return nil
            }
        }
        
        return deeplinks
    }
}
