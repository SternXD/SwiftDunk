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
        // Test SwiftDunk initialization with little configuration
        let config = SwiftDunkConfiguration(
            environment: .production
        )
        
        let swiftDunk = SwiftDunk(configuration: config)
        
        // Verify core services were initialized
        XCTAssertNotNil(swiftDunk.auth)
        XCTAssertNotNil(swiftDunk.anisette)
        XCTAssertNotNil(swiftDunk.xcode)
        
        // Verify developer model services
        XCTAssertNotNil(swiftDunk.accounts)
        XCTAssertNotNil(swiftDunk.apps)
        XCTAssertNotNil(swiftDunk.devices)
        XCTAssertNotNil(swiftDunk.teams)
    }
    
    func testSwiftDunkConfigurationWithCustomValues() throws {
        // Test SwiftDunk initialization with custom configuration
        let config = SwiftDunkConfiguration(
            environment: .sandbox,
            anisetteServerURL: "https://ani.example.com",
            deviceSerial: "ABCD1234"
        )
        
        let swiftDunk = SwiftDunk(configuration: config)
        
        // Verify anisette configuration
        XCTAssertEqual(swiftDunk.anisette.url?.absoluteString, "https://ani.example.com")
        XCTAssertEqual(swiftDunk.anisette.serial, "ABCD1234")
        
        // Verify environment configuration by checking configuration values
        XCTAssertEqual(config.environment, .sandbox)
        XCTAssertEqual(config.anisetteServerURL, "https://ani.example.com")
        XCTAssertEqual(config.deviceSerial, "ABCD1234")
    }
    
    func testVersionString() {
        // Test version number is available and follows semver
        XCTAssertFalse(SwiftDunk.version.isEmpty)
        
        // Verify version follows semantic versioning (x.y.z)
        let versionComponents = SwiftDunk.version.split(separator: ".")
        XCTAssertEqual(versionComponents.count, 3, "Version should follow semantic versioning (x.y.z)")
        
        // Verify each component is a number
        for component in versionComponents {
            XCTAssertNotNil(Int(component), "Version component should be a number")
        }
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
