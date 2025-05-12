//
//  DeepLinkParser.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 10.05.2025..
//

import Foundation

enum Route: Equatable {
    enum PresentationStyle: String {
        case present
        case push
    }
    
    case account
    case login
    case home
    case screenA(presentationStyle: PresentationStyle)
    case screenB(id: Int)
    case screenC
}

enum DeepLinkParser {
    struct DeepLink: Decodable {
        let value: String
        let parameters: [String: String]?
    }
    
    enum Error: Swift.Error {
        case missingParameter(String)
        case typeCastingFailed(parameter: String, type: String)
        case unsupportedType(String)
    }
    
    enum Parameter: String {
        case id
        case presentationStyle
    }
    
    static func parse(_ url: URL) -> [Route] {
        guard
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            urlComponents.host == "deeplink",
            let queryItems = urlComponents.queryItems,
            let payload = queryItems.first(where: { $0.name == "payload" })?.value,
            let data = Data(base64Encoded: payload),
            let items = try? JSONDecoder().decode([DeepLink].self, from: data)
        else { return [] }
        
        let routes: [Route]
        
        do {
            routes = try items.compactMap { item throws -> Route? in
                switch item.value {
                case "account":
                    return .account
                case "login":
                    return .login
                case "home":
                    return .home
                case "screenA":
                    let presentationStyle = try extract(parameter: .presentationStyle, from: item.parameters, as: Route.PresentationStyle.self)
                    return .screenA(presentationStyle: presentationStyle)
                case "screenB":
                    let id = try extract(parameter: .id, from: item.parameters, as: Int.self)
                    return .screenB(id: id)
                case "screenC":
                    return .screenC
                default:
                    return nil
                }
            }
        } catch {
            routes = []
            print("DeepLink parsing failed: \(error)")
        }
        
        return routes
    }
    
    static func extract<T>(parameter: Parameter, from parameters: [String: String]?, as type: T.Type) throws -> T {
        guard let value = parameters?[parameter.rawValue] else {
            throw Error.missingParameter(parameter.rawValue)
        }
        
        switch type {
        case is String.Type:
            guard let stringValue = value as? T else {
                throw Error.typeCastingFailed(parameter: parameter.rawValue, type: String(describing: String.self))
            }
            return stringValue
            
        case is Int.Type:
            guard let intValue = Int(value) as? T else {
                throw Error.typeCastingFailed(parameter: parameter.rawValue, type: String(describing: Int.self))
            }
            
            return intValue
        case is Double.Type:
            guard let doubleValue = Double(value) as? T else {
                throw Error.typeCastingFailed(parameter: parameter.rawValue, type: String(describing: Double.self))
            }
            
            return doubleValue
        case is Bool.Type:
            guard let boolValue = Bool(value) as? T else {
                throw Error.typeCastingFailed(parameter: parameter.rawValue, type: String(describing: Bool.self))
            }
            
            return boolValue
        case let rawRepresentableType as any RawRepresentable<String>.Type:
            guard let enumValue = rawRepresentableType.init(rawValue: value) as? T else {
                throw Error.typeCastingFailed(parameter: parameter.rawValue, type: String(describing: rawRepresentableType.self))
            }
            
            return enumValue
        default:
            throw Error.unsupportedType(String(describing: T.self))
        }
    }
}
