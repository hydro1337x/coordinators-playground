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
    
    case account(authToken: String?)
    case accountDetails
    case login
    case home
    case screenA
    case screenB(id: Int, presentationStyle: PresentationStyle)
    case screenC
}

enum DeepLinkParser {
    struct DeepLink: Decodable {
        let value: String
        let parameters: Parameters?
        
        struct Parameters: Decodable {
            let items: [String:Any]
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: AnyCodingKeys.self)
                items = try container.decode([String:Any].self)
            }
        }
    }
    
    enum Error: Swift.Error {
        case missingParameter(String)
        case typeCastingFailed(parameter: String, type: String)
        case unsupportedType(String)
    }
    
    enum Parameter: String {
        case id
        case presentationStyle
        case authToken
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
                    let authToken = try extract(parameter: .authToken, from: item.parameters?.items, as: String?.self)
                    return .account(authToken: authToken)
                case "accountDetails":
                    return .accountDetails
                case "login":
                    return .login
                case "home":
                    return .home
                case "screenA":
                    return .screenA
                case "screenB":
                    let presentationStyle = try extract(parameter: .presentationStyle, from: item.parameters?.items, as: Route.PresentationStyle.self)
                    let id = try extract(parameter: .id, from: item.parameters?.items, as: Int.self)
                    return .screenB(id: id, presentationStyle: presentationStyle)
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
    
    static func tryCast<T: StringParsable>(_ value: Any, as type: T.Type) -> T? {
        if let typeValue = value as? T {
            return typeValue
        } else if let stringValue = value as? String, let typeValue = T(stringValue) {
            return typeValue
        } else {
            return nil
        }
    }
    
    static func extract<T>(parameter: Parameter, from parameters: [String: Any]?, as type: T.Type) throws -> T {
        let value = parameters?[parameter.rawValue]
        
        if !isOptional(value) && value == nil {
            throw Error.missingParameter(parameter.rawValue)
        }
        
        switch type {
        case is String.Type:
            guard let stringValue = value as? T else {
                throw Error.typeCastingFailed(parameter: parameter.rawValue, type: String(describing: T.self))
            }
            return stringValue
        case is Optional<String>.Type:
            guard let stringValue = value as? T else {
                throw Error.typeCastingFailed(parameter: parameter.rawValue, type: String(describing: T.self))
            }
            return stringValue
            
        case is Int.Type:
            if let v: Int = tryCast(value as Any, as: Int.self), let value = v as? T {
                return value
            } else {
                throw Error.typeCastingFailed(parameter: parameter.rawValue, type: String(describing: T.self))
            }
        case is Double.Type:
            if let v: Double = tryCast(value as Any, as: Double.self), let value = v as? T {
                return value
            } else {
                throw Error.typeCastingFailed(parameter: parameter.rawValue, type: String(describing: T.self))
            }
        case is Bool.Type:
            if let v: Bool = tryCast(value as Any, as: Bool.self), let value = v as? T {
                return value
            } else {
                throw Error.typeCastingFailed(parameter: parameter.rawValue, type: String(describing: T.self))
            }
        default:
            throw Error.unsupportedType(String(describing: T.self))
        }
    }
    
    static func extract<T: RawRepresentable>(parameter: Parameter, from parameters: [String: Any]?, as type: T.Type) throws -> T {
        // Add better errors
        guard let rawValue = parameters?[parameter.rawValue] as? T.RawValue else {
            throw Error.typeCastingFailed(parameter: parameter.rawValue, type: String(describing: T.self))
        }
        
        guard let enumValue = T(rawValue: rawValue) else {
            throw Error.unsupportedType(String(describing: T.self))
        }
        
        return enumValue
    }
}


protocol StringParsable {
    init?(_ string: String)
}

extension Bool: StringParsable {}
extension Int: StringParsable {}
extension Double: StringParsable {}


struct AnyCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) { self.stringValue = stringValue }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer {
    func decode(_ type: [Any].Type, forKey key: K) throws -> [Any] {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: [Any].Type, forKey key: K) throws -> [Any]? {
        guard contains(key) else { return .none }
        return try decode(type, forKey: key)
    }
    
    func decode(_ type: [String:Any].Type, forKey key: K) throws -> [String:Any] {
        let container = try nestedContainer(keyedBy: AnyCodingKeys.self, forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: [String:Any].Type, forKey key: K) throws -> [String:Any]? {
        guard contains(key) else { return .none }
        return try decode(type, forKey: key)
    }
    
    func decode(_ type: [String:Any].Type) throws -> [String:Any] {
        var dictionary = [String:Any]()
        
        allKeys.forEach { key in
            if let value = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = value
            } else if let value = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = value
            } else if let value = try? decode(Int64.self, forKey: key) {
                dictionary[key.stringValue] = value
            } else if let value = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = value
            } else if let value = try? decode([String:Any].self, forKey: key) {
                dictionary[key.stringValue] = value
            } else if let value = try? decode([Any].self, forKey: key) {
                dictionary[key.stringValue] = value
            }
        }
        
        return dictionary
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode(_ type: [Any].Type) throws -> [Any] {
        var array = [Any]()
        
        while isAtEnd == false {
            if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let value = try? decode(Int64.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode([String:Any].self) {
                array.append(value)
            } else if let value = try? decode([Any].self) {
                array.append(value)
            }
        }
        
        return array
    }
    
    mutating func decode(_ type: [String:Any].Type) throws -> [String:Any] {
        let nestedContainer = try self.nestedContainer(keyedBy: AnyCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}

func isOptional<T>(_ value: T) -> Bool {
    return Mirror(reflecting: value).displayStyle == .optional
}
