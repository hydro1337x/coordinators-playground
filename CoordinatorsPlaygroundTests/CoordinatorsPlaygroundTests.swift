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

    @Test func example() async throws {
        let url = URL(string: "coordinatorsplayground://tabs/home/screenA/screenB/screenC?screenBID=1")!
        
        #expect(DeepLinkParser.parse(url) == [.tabs, .home, .screenA, .screenB(id: 1), .screenC])
    }

}
