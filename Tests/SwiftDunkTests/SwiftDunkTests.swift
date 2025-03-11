//
//  SwiftDunkTests.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import XCTest
@testable import SwiftDunk

final class SwiftDunkTests: XCTestCase {
    func testSwiftDunkInitialization() throws {
        // Test SwiftDunk initialization with configuration
        let config = SwiftDunkConfiguration(
            environment: .production
        )
        
        let swiftDunk = SwiftDunk(configuration: config)
        
        // Verify services were initialized
        XCTAssertNotNil(swiftDunk.auth)
        XCTAssertNotNil(swiftDunk.anisette)
        XCTAssertNotNil(swiftDunk.xcode)
    }
    
    func testVersionString() {
        // Test version number is available
        XCTAssertFalse(SwiftDunk.version.isEmpty)
    }
    
    // This test can be run when you want to verify actual authentication
    // Comment out this test during normal development
    /*
    func testAuth() async throws {
        let config = SwiftDunkConfiguration(
            environment: .production
        )
        
        let swiftDunk = SwiftDunk(configuration: config)
        
        // This is for manual testing only - add real credentials when needed
        // let result = try await swiftDunk.auth.authenticate(
        //     username: "test@example.com",
        //     password: "password"
        // )
        
        // XCTAssertNotNil(result)
    }
    */
}
