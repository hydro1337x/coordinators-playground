//
//  CoordinatorsPlaygroundTests.swift
//  CoordinatorsPlaygroundTests
//
//  Created by Benjamin Macanovic on 09.05.2025..
//

import Foundation
import Testing
@testable import CoordinatorsPlayground

struct CoordinatorsPlaygroundTests {
    
//    {
//      "step": {
//        "type": "flow",
//        "value": "tabs"
//      },
//      "children": [
//        {
//          "step": {
//            "type": "tab",
//            "value": "home"
//          },
//          "children": [
//            {
//              "step": {
//                "type": "push",
//                "value": "screenA"
//              },
//              "children": []
//            },
//            {
//              "step": {
//                "type": "push",
//                "value": {
//                  "value": "screenB",
//                  "id": 1
//                }
//              },
//              "children": []
//            },
//            {
//              "step": {
//                "type": "push",
//                "value": "screenC"
//              },
//              "children": []
//            }
//          ]
//        }
//      ]
//    }

    @Test func example() async throws {
        let url = URL(string: "coordinatorsplayground://deeplink?payload=W3sidmFsdWUiOiAidGFicyJ9LCB7InZhbHVlIjogImhvbWUifSwgeyJ2YWx1ZSI6ICJzY3JlZW5BIn0sIHsidmFsdWUiOiAic2NyZWVuQiIsICJwYXJhbWV0ZXJzIjogeyJpZCI6ICIxIn19LCB7InZhbHVlIjogInNjcmVlbkMifV0=")!
        
        #expect(DeepLinkParser.parse(url) == [.tabs, .home, .screenA, .screenB(id: 1), .screenC])
    }

}
