//
//  Configuration.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//

import Foundation

extension SwiftDunk {
    /// Configuration for SwiftDunk
    public struct Configuration {
        public let apiKey: String?
        public let environment: Environment
        public let anisetteServerURL: String?
        public let deviceSerial: String?
        
        public init(
            apiKey: String? = nil,
            environment: Environment = .production,
            anisetteServerURL: String? = nil,
            deviceSerial: String? = nil
        ) {
            self.apiKey = apiKey
            self.environment = environment
            self.anisetteServerURL = anisetteServerURL
            self.deviceSerial = deviceSerial
        }
    }
    
    /// Environment for Apple's Authentication services
    public enum Environment {
        case production
        case custom(URL)
        
        var baseURL: URL {
            switch self {
            case .production:
                return URL(string: "https://gsa.apple.com/")!
            case .custom(let url):
                return url
            }
        }
    }
}
