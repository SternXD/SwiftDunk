//
//  SwiftDunk.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation

/// SwiftDunk - Swift implementation for Apple's Grand Slam Authentication APIs
public struct SwiftDunk {
    public static let version = "1.0.0"
    
    // Service properties
    public let auth: GSAuth
    public let anisette: Anisette
    public let xcode: XcodeService
    
    // Developer model services
    public let accounts: AccountService
    public let apps: AppService
    public let devices: DeviceService
    public let teams: TeamService
    
    /// Initialize SwiftDunk with configuration
    /// - Parameter configuration: Configuration for SwiftDunk services
    public init(configuration: SwiftDunkConfiguration) {
        // Create network client
        let client = NetworkClient(
            baseURL: configuration.environment.baseURL
        )
        
        // Initialize anisette
        let anisetteServerURL = configuration.anisetteServerURL != nil ?
            URL(string: configuration.anisetteServerURL!) : nil
            
        let anisetteInstance = Anisette(
            url: anisetteServerURL,
            serial: configuration.deviceSerial
        )
        
        // Initialize services
        self.auth = GSAuth(anisette: anisetteInstance)
        self.anisette = anisetteInstance
        self.xcode = XcodeService(client: client)
        
        // Initialize model services
        self.accounts = AccountService(client: client)
        self.apps = AppService(client: client)
        self.devices = DeviceService(client: client)
        self.teams = TeamService(client: client)
    }
}

/// Configuration for SwiftDunk
public struct SwiftDunkConfiguration {
    public let environment: SwiftDunkEnvironment
    public let anisetteServerURL: String?
    public let deviceSerial: String?
    
    /// Initialize configuration
    /// - Parameters:
    ///   - environment: API environment
    ///   - anisetteServerURL: anisette server URL
    ///   - deviceSerial: device serial number
    public init(
        environment: SwiftDunkEnvironment,
        anisetteServerURL: String? = nil,
        deviceSerial: String? = nil
    ) {
        self.environment = environment
        self.anisetteServerURL = anisetteServerURL
        self.deviceSerial = deviceSerial
    }
}

/// API environment
public enum SwiftDunkEnvironment {
    case production
    case sandbox
    
    var baseURL: URL {
        switch self {
        case .production:
            return URL(string: "https://developer.apple.com/services-account/v1")!
        case .sandbox:
            return URL(string: "https://sandbox.developer.apple.com/services-account/v1")!
        }
    }
}
