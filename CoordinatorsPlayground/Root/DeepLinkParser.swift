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

// MARK: - Refactor

struct Route: Decodable {
    let step: Step
    let children: [Route]
}

extension Route {
    enum Flow: String, Decodable {
        case tabs
    }
    
    enum Tab: String, Decodable {
        case home
        case profile
    }
    
    enum Path: Decodable {
        case accountDetails
        case screenA
        case screenB(id: Int)
        case screenC
        
        enum CodingKeys: String, CodingKey {
            case value
            case id
        }
        
        init(from decoder: any Decoder) throws {
            if let container = try? decoder.singleValueContainer(), let stringValue = try? container.decode(String.self) {
                switch stringValue {
                case "screenA": self = .screenA
                case "screenC": self = .screenC
                case "accountDetails": self = .accountDetails
                default:
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid simple value for Path")
                }
                return
            }
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let value = try container.decode(String.self, forKey: .value)
            
            switch value {
            case "screenB":
                let id = try container.decode(Int.self, forKey: .id)
                self = .screenB(id: id)
            default:
                throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Invalid complex value for Path")
            }
        }
    }
    
    enum Destination: Decodable {
        case login
        case account(authToken: String?)
        case screenB(id: Int)
        
        enum CodingKeys: String, CodingKey {
            case value
            case id
            case authToken
        }
        
        init(from decoder: any Decoder) throws {
            if let container = try? decoder.singleValueContainer(), let stringValue = try? container.decode(String.self) {
                switch stringValue {
                case "login": self = .login
                default:
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid simple value for Destination")
                }
                return
            }
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let value = try container.decode(String.self, forKey: .value)
            
            switch value {
            case "screenB":
                let id = try container.decode(Int.self, forKey: .id)
                self = .screenB(id: id)
            case "account":
                let authToken = try container.decode(String?.self, forKey: .authToken)
                self = .account(authToken: authToken)
            default:
                throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Invalid complex value for Destination")
            }
        }
    }
    
    enum Step: Decodable {
        case flow(Flow)
        case tab(Tab)
        case push(Path)
        case present(Destination)
        
        private enum CodingKeys: String, CodingKey {
            case type
            case value
        }
        
        private enum StepType: String, Decodable {
            case flow
            case tab
            case push
            case present
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(StepType.self, forKey: .type)
            
            switch type {
            case .flow:
                let flow = try container.decode(Flow.self, forKey: .value)
                self = .flow(flow)
            case .tab:
                let tab = try container.decode(Tab.self, forKey: .value)
                self = .tab(tab)
            case .push:
                let screen = try container.decode(Path.self, forKey: .value)
                self = .push(screen)
            case .present:
                let modal = try container.decode(Destination.self, forKey: .value)
                self = .present(modal)
            }
        }
    }
}
