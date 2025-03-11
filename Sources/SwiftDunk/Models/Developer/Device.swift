//
//  Device.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation

public struct Device: Codable, Sendable {
    public let id: String
    public let name: String
    public let udid: String
    public let platform: Platform
    public let status: Status
    public let addedDate: Date
    
    public enum Platform: String, Codable, Sendable {
        case iOS
        case iPadOS
        case macOS
        case tvOS
        case watchOS
    }
    
    public enum Status: String, Codable, Sendable {
        case active
        case disabled
        case development
    }
}

public class DeviceService {
    private let client: NetworkClient
    
    init(client: NetworkClient) {
        self.client = client
    }
    
    public func getDevice(id: String) async throws -> Device {
        return try await client.request("devices/\(id)")
    }
    
    public func getDevices(platform: Device.Platform? = nil) async throws -> [Device] {
        var endpoint = "devices"
        if let platform = platform {
            endpoint += "?platform=\(platform.rawValue)"
        }
        return try await client.request(endpoint)
    }
    
    public func registerDevice(name: String, udid: String, platform: Device.Platform) async throws -> Device {
        return try await client.request(
            "devices",
            method: .post,
            parameters: [
                "name": name,
                "udid": udid,
                "platform": platform.rawValue
            ] as [String: String]
        )
    }
    
    public func updateDeviceStatus(id: String, status: Device.Status) async throws -> Device {
        return try await client.request(
            "devices/\(id)/status",
            method: .patch,
            parameters: ["status": status.rawValue] as [String: String]
        )
    }
}
