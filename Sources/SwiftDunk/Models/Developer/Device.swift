//
//  Device.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation

public struct Device: Codable, Identifiable {
    public let id: String
    public let name: String
    public let udid: String
    public let deviceClass: DeviceClass
    public let status: DeviceStatus
    public let addedDate: Date
    public let teamId: String
    
    public enum DeviceClass: String, Codable {
        case iPhone
        case iPad
        case iPod
        case appleTv = "apple_tv"
        case mac
        case watch
    }
    
    public enum DeviceStatus: String, Codable {
        case enabled
        case disabled
    }
}

public class DeviceService {
    private let client: NetworkClient
    
    init(client: NetworkClient) {
        self.client = client
    }
    
    /// Get device details
    /// - Parameter deviceId: Device ID to fetch
    /// - Returns: Device details
    public func getDevice(id deviceId: String) async throws -> Device {
        return try await client.request("developer/devices/\(deviceId)")
    }
    
    /// List all devices
    /// - Returns: List of all devices
    public func listDevices() async throws -> [Device] {
        return try await client.request("developer/devices")
    }
    
    /// Register a new device
    /// - Parameter device: Device information for registration
    /// - Returns: Registered device details
    public func registerDevice(_ device: DeviceRegistrationInfo) async throws -> Device {
        return try await client.request(
            "developer/devices",
            method: .post,
            parameters: device.toDictionary()
        )
    }
}

public struct DeviceRegistrationInfo: Codable {
    public let name: String
    public let udid: String
    public let deviceClass: Device.DeviceClass
    public let teamId: String
    
    public func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "udid": udid,
            "device_class": deviceClass.rawValue,
            "team_id": teamId
        ]
    }
}