//
//  GSAuthTokens.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation

public struct GSAuthTokens {
    public let tokens: [GSAuthToken]
    
    public init(_ tokenArray: [[String: Any]]) {
        self.tokens = tokenArray.map { GSAuthToken(dictionary: $0) }
    }
}

public struct GSAuthToken {
    public let type: String
    public let authServiceUrl: String?
    public let authServiceKey: String?
    public let token: String
    public let expiryTime: Date?
    
    init(dictionary: [String: Any]) {
        self.type = dictionary["token_type"] as? String ?? "unknown"
        self.authServiceUrl = dictionary["auth_service_url"] as? String
        self.authServiceKey = dictionary["auth_service_key"] as? String
        self.token = dictionary["token"] as? String ?? ""
        
        if let expiryTimeString = dictionary["expiry_time"] as? String {
            let formatter = ISO8601DateFormatter()
            self.expiryTime = formatter.date(from: expiryTimeString)
        } else {
            self.expiryTime = nil
        }
    }
}
