//
//  App.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation

public struct App: Codable, Identifiable {
    public let id: String
    public let bundleId: String
    public let name: String
    public let sku: String?
    public let appStoreState: AppStoreState?
    public let platform: Platform
    public let teamId: String
    public let createdAt: Date
    public let updatedAt: Date
    
    public enum AppStoreState: String, Codable {
        case accepted
        case rejected
        case pendingReview = "pending_review"
        case inReview = "in_review"
        case waitingForUpload = "waiting_for_upload"
        case readyForSale = "ready_for_sale"
        case developerRemovedFromSale = "developer_removed_from_sale"
    }
    
    public enum Platform: String, Codable {
        case iOS
        case macOS
        case tvOS
        case watchOS
    }
}

public class AppService {
    private let client: NetworkClient
    
    init(client: NetworkClient) {
        self.client = client
    }
    
    /// Get app details
    /// - Parameter appId: App ID to fetch
    /// - Returns: App details
    public func getApp(id appId: String) async throws -> App {
        return try await client.request("developer/apps/\(appId)")
    }
    
    /// List all apps
    /// - Returns: List of all apps
    public func listApps() async throws -> [App] {
        return try await client.request("developer/apps")
    }
    
    /// Create a new app
    /// - Parameter app: App information for creation
    /// - Returns: Created app details
    public func createApp(_ app: AppCreationInfo) async throws -> App {
        return try await client.request(
            "developer/apps",
            method: .post,
            parameters: app.toDictionary()
        )
    }
}

public struct AppCreationInfo: Codable {
    public let name: String
    public let bundleId: String
    public let platform: App.Platform
    public let teamId: String
    
    public func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "bundle_id": bundleId,
            "platform": platform.rawValue,
            "team_id": teamId
        ]
    }
}