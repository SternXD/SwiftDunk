//
//  Anisette.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation

public class Anisette {
    public let url: URL?
    public let serial: String?
    
    public init(url: URL? = nil, serial: String? = nil) {
        self.url = url
        self.serial = serial
    }
    
    /// Get anisette headers for authentication
    /// - Parameter includeUser: Whether to include user headers
    /// - Returns: Headers dictionary
    public func headers(includeUser: Bool = false) -> [String: String] {
        var headers: [String: String] = [
            "X-Apple-I-Client-Time": ISO8601DateFormatter().string(from: Date()),
            "X-Apple-I-TimeZone": TimeZone.current.identifier,
            "X-Apple-I-MD": "AAAABQAAABCQG6ZZvz8sE7Jy1bU+SmUEAAAAAg==",
            "X-Apple-I-MD-M": "ZYlG+3S4lki0S0/R18/Qhw4Xio88tO+AKMvAqzLqj0B9MHeS0dk9zKm5mMC+X2+xD4XdA5iaJpEYsgyOpM5uCZTXoDviCYHV/8r1AqjwBktFiA==",
            "X-Apple-I-MD-LU": "",
            "X-Apple-I-MD-RINFO": "17106176",
            "X-Apple-I-SRL-NO": serial ?? "0",
            "X-Mme-Device-Id": "D1C543E0-5A41-4CE3-A72A-A8FE588B6111",
            "X-Mme-Client-Info": clientInfo()
        ]
        
        if includeUser {
            headers["X-Apple-I-OAuth-Token"] = "dXNlcl9pZD0wJnBhaXJfc2VjPTE0OWM0MjE3M2VmNjlkNmNkZmQxNDM1YzgzMWRkZjM3"
        }
        
        return headers
    }
    
    /// Get client info for anisette request
    /// - Returns: Client info string
    public func clientInfo() -> String {
        return "<MacBookPro16,1> <Mac OS X;13.5.2;22G91> <com.apple.AuthKit/1 (com.apple.dt.Xcode/3594.4.19)>"
    }
    
    /// Fetch anisette data from server
    /// - Returns: Dictionary with anisette headers
    public func fetchAnisetteData() async throws -> [String: String] {
        // If a custom anisette server URL is provided, fetch data from there
        if let url = url {
            let request = URLRequest(url: url)
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Parse response
            let json = try JSONDecoder().decode([String: String].self, from: data)
            return json
        }
        
        // Otherwise, use locally generated data
        return headers()
    }
}
