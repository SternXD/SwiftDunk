//
//  SwiftDunk.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation
import Crypto
import SRP
import Alamofire

/// SwiftDunk - Swift implementation of PyDunk for Apple's Grand Slam Authentication APIs
public struct SwiftDunk {
    public static let version = "1.0.0"
    
    // Service properties
    public let auth: AuthService
    public let anisette: AnisetteService
    public let xcode: XcodeService
    
    // Developer model services
    public let accounts: AccountService
    public let apps: AppService
    public let devices: DeviceService
    public let teams: TeamService
    
    /// Initialize SwiftDunk with configuration
    /// - Parameter configuration: Configuration for SwiftDunk services
    public init(configuration: Configuration) {
        // Create network client
        let client = NetworkClient(
            baseURL: configuration.environment.baseURL,
            apiKey: configuration.apiKey
        )
        
        // Initialize services
        self.auth = AuthService(client: client)
        self.anisette = AnisetteService(client: client)
        self.xcode = XcodeService(client: client)
        
        // Initialize model services
        self.accounts = AccountService(client: client)
        self.apps = AppService(client: client)
        self.devices = DeviceService(client: client)
        self.teams = TeamService(client: client)
    }
}
