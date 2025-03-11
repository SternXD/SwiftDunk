//
//  App.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation

public struct App: Codable, Sendable {
    public let id: String
    public let bundleId: String
    public let name: String
    public let platform: Platform
    public let version: String
    public let buildNumber: String
    public let status: Status
    public let teamId: String
    
    public enum Platform: String, Codable, Sendable {
        case ios
        case macOS
        case tvOS
        case watchOS
    }
    
    public enum Status: String, Codable, Sendable {
        case development
        case inReview
        case approved
        case rejected
    }
}

public class AppService {
    private let client: NetworkClient
    
    init(client: NetworkClient) {
        self.client = client
    }
    
    public func getApp(id: String) async throws -> App {
        return try await client.request("apps/\(id)")
    }
    
    public func getApps(teamId: String? = nil) async throws -> [App] {
        var endpoint = "apps"
        if let teamId = teamId {
            endpoint += "?teamId=\(teamId)"
        }
        return try await client.request(endpoint)
    }
    
    public func createApp(bundleId: String, name: String, platform: App.Platform) async throws -> App {
        return try await client.request(
            "apps",
            method: .post,
            parameters: [
                "bundleId": bundleId,
                "name": name,
                "platform": platform.rawValue
            ] as [String: String]
        )
    }
    
    public func updateApp(id: String, details: [String: String]) async throws -> App {
        return try await client.request(
            "apps/\(id)",
            method: .patch,
            parameters: details
        )
    }
}
