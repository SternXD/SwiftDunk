//
//  XcodeSession.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//

import Foundation

public class XcodeService {
    private let client: NetworkClient
    
    init(client: NetworkClient) {
        self.client = client
    }
    
    /// Get available Xcode versions
    /// - Returns: List of available Xcode versions
    public func getVersions() async throws -> [XcodeVersion] {
        return try await client.request("xcode/versions")
    }
    
    /// Download Xcode version
    /// - Parameter version: Xcode version to download
    /// - Returns: Download information
    public func downloadVersion(_ version: String) async throws -> XcodeDownloadInfo {
        return try await client.request(
            "xcode/download",
            method: .post,
            parameters: ["version": version]
        )
    }
}

public class XcodeSession {
    public let dsid: String
    public let token: [String: Any]
    private let anisette: Anisette
    
    public init(dsid: String, token: [String: Any], anisette: Anisette) {
        self.dsid = dsid
        self.token = token
        self.anisette = anisette
    }
    
    public var authorizationHeaders: [String: String] {
        var headers = anisette.headers(includeUser: true)
        
        if let serviceKey = token["auth_service_key"] as? String,
           let tokenString = token["token"] as? String {
            headers["X-Apple-Identity-Token"] = tokenString
            headers["X-Apple-Authorization-Key"] = serviceKey
            headers["X-Apple-DSID"] = dsid
        }
        
        return headers
    }
}

public struct XcodeVersion: Codable, Sendable {
    public let version: String
    public let buildNumber: String
    public let releaseDate: Date
    public let downloadSize: Int64
    public let releaseNotes: String?
}

public struct XcodeDownloadInfo: Codable, Sendable {
    public let downloadURL: URL
    public let version: String
    public let expiresAt: Date
}
