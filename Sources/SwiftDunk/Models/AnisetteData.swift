//
//  AnisetteData.swift
//  SwiftDunk
//
//  Created by SternXD on 3/10/25.
//


import Foundation

public struct AnisetteData: Codable {
    public let machineId: String
    public let oneTimePassword: String
    public let deviceId: String
    public let routingInfo: String
    
    public init(
        machineId: String,
        oneTimePassword: String,
        deviceId: String,
        routingInfo: String
    ) {
        self.machineId = machineId
        self.oneTimePassword = oneTimePassword
        self.deviceId = deviceId
        self.routingInfo = routingInfo
    }
    
    public func toDictionary() -> [String: String] {
        return [
            "X-Apple-I-MD": machineId,
            "X-Apple-I-MD-M": oneTimePassword,
            "X-Apple-I-MD-RINFO": routingInfo,
            "X-Apple-I-SRL-NO": deviceId
        ]
    }
}