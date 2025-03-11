//
//  SwiftDunkTests.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import XCTest
@testable import SwiftDunk

final class SwiftDunkTests: XCTestCase {
    func testConfigurationInitialization() {
        let config = SwiftDunk.Configuration(
            apiKey: "test-api-key",
            environment: .development
        )
        
        XCTAssertEqual(config.apiKey, "test-api-key")
        XCTAssertEqual(config.environment.baseURL.absoluteString, "https://api.development.apple.com/")
    }
    
    func testSwiftDunkInitialization() {
        let config = SwiftDunk.Configuration(
            apiKey: "test-api-key",
            environment: .development
        )
        
        let swiftDunk = SwiftDunk(configuration: config)
        
        // Verify services were initialized
        XCTAssertNotNil(swiftDunk.auth)
        XCTAssertNotNil(swiftDunk.anisette)
        XCTAssertNotNil(swiftDunk.xcode)
        
        // Verify model services were initialized
        XCTAssertNotNil(swiftDunk.accounts)
        XCTAssertNotNil(swiftDunk.apps)
        XCTAssertNotNil(swiftDunk.devices)
        XCTAssertNotNil(swiftDunk.teams)
    }
}
