//
//  GSAuth.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//

import Foundation
import Crypto
import CryptoKit

public class GSAuth {
    private let anisette: Anisette
    private let baseURL = URL(string: "https://gsa.apple.com/grandslam/GsService2")!
    
    public init(anisette: Anisette) {
        self.anisette = anisette
    }
    
    /// Authenticate with Apple ID
    /// - Parameters:
    ///   - username: Apple ID username
    ///   - password: Apple ID password
    /// - Returns: Authentication result
    public func authenticate(username: String, password: String) async throws -> [String: Any] {
        // Step 1: Initialize SRP
        let srpClient = try initializeSRP(username: username, password: password)
        
        // Step 2: Start authentication
        let authData = try await startAuthentication(username: username, srpClient: srpClient)
        
        // Step 3: Complete authentication
        let token = try await completeAuthentication(
            username: username,
            password: password,
            srpClient: srpClient,
            authData: authData
        )
        
        return token
    }
    
    /// Fetch Xcode authentication token
    /// - Parameters:
    ///   - username: Apple ID username
    ///   - password: Apple ID password
    /// - Returns: Xcode session information
    public func fetchXcodeToken(username: String, password: String) async throws -> ([String: Any], [String: Any]) {
        // Step 1: Authenticate with Apple ID
        let authToken = try await authenticate(username: username, password: password)
        
        // Step 2: Request Xcode specific session
        let xcodeSession = try await requestXcodeSession(authToken: authToken)
        
        return (authToken, xcodeSession)
    }
    
    // MARK: - Private Authentication Methods
    
    private func startAuthentication(username: String, srpClient: SRPClient<SHA256>) async throws -> [String: Any] {
        // Prepare request body
        let requestBody: [String: Any] = [
            "A2k": srpClient.publicKey.hexEncodedString(),
            "cpd": anisette.clientInfo(),
            "o": "init",
            "ps": [
                [
                    "k": "username",
                    "v": username
                ]
            ],
            "u": baseURL.absoluteString
        ]
        
        // Make request
        let response = try await makeRequest(endpoint: "/initLogin", body: requestBody)
        
        // Handle response
        guard let sp = response["sp"] as? String,
              let cpd = response["cpd"] as? [String: Any] else {
            throw AuthError.missingData
        }
        
        return [
            "sp": sp,
            "cpd": cpd,
        ]
    }
    
    private func completeAuthentication(
        username: String,
        password: String,
        srpClient: SRPClient<SHA256>,
        authData: [String: Any]
    ) async throws -> [String: Any] {
        guard let sp = authData["sp"] as? String,
              let cpd = authData["cpd"] as? [String: Any] else {
            throw AuthError.missingData
        }
        
        // Process server public key
        let serverPublicKey = try Data(hexString: sp)
        let sessionKey = try srpClient.processServerPublicKey(serverPublicKey)
        
        // Calculate M1 proof
        let M1 = srpClient.clientProof.hexEncodedString()
        
        // Encrypt password
        let encryptedPassword = try encryptPassword(password: password, sessionKey: sessionKey)
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "c": encryptedPassword,
            "cpd": cpd,
            "M1": M1,
            "o": "complete",
            "u": baseURL.absoluteString
        ]
        
        // Make request
        let response = try await makeRequest(endpoint: "/completeLogin", body: requestBody)
        
        return response
    }
    
    private func requestXcodeSession(authToken: [String: Any]) async throws -> [String: Any] {
        guard let sessionID = authToken["sessionID"] as? String else {
            throw AuthError.missingData
        }
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "clientID": "XABBG36SBA",
            "cpd": anisette.clientInfo(),
            "headers": [
                "XAppVersion": "1.0",
                "X-Apple-App-Info": "com.apple.gs.xcode.auth",
                "X-Xcode-Version": "14.3"
            ],
            "prototype": "com.apple.dt.Xcode.extension",
            "sessionID": sessionID,
            "u": baseURL.absoluteString
        ]
        
        // Make request
        let response = try await makeRequest(endpoint: "/registerExtension", body: requestBody)
        
        return response
    }
    
    // MARK: - Helper Methods
    
    private func initializeSRP(username: String, password: String) throws -> SRPClient<SHA256> {
        // Setup SRP configuration
        let config = SRPConfiguration<SHA256>(
            algorithm: .sha256,
            group: .N2048,
            username: username,
            password: password
        )
        
        // Create SRP client
        return try SRPClient<SHA256>(configuration: config)
    }
    
    private func encryptPassword(password: String, sessionKey: Data) throws -> String {
        // Generate random IV
        let iv = SymmetricKey(size: .bits128).withUnsafeBytes { Data($0) }
        
        // Create encryption key from first 16 bytes of session key
        let keyData = sessionKey.prefix(16)
        let key = SymmetricKey(data: keyData)
        
        // Convert password to data
        guard let passwordData = password.data(using: .utf8) else {
            throw AuthError.invalidData
        }
        
        // Encrypt using AES-GCM
        let sealedBox = try AES.GCM.seal(passwordData, using: key, nonce: AES.GCM.Nonce(data: iv))
        
        // Return base64 encoded result
        guard let combined = sealedBox.combined else {
            throw AuthError.encryptionFailed
        }
        
        return combined.base64EncodedString()
    }
    
    private func makeRequest(endpoint: String, body: [String: Any]) async throws -> [String: Any] {
        // Create URL
        let url = baseURL.appendingPathComponent(endpoint)
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add additional headers from anisette
        let headers = anisette.headers(includeUser: true)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Serialize body to JSON
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        // Make request using URLSession
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthError.invalidResponse
        }
        
        // Check for errors
        if let errorCode = json["ec"] as? Int, errorCode != 0,
           let errorDescription = json["ed"] as? String {
            throw AuthError.serverError(code: errorCode, description: errorDescription)
        }
        
        return json
    }
    
    // MARK: - Error Types
    
    public enum AuthError: Error {
        case invalidData
        case missingData
        case invalidResponse
        case encryptionFailed
        case serverError(code: Int, description: String)
    }
}

// MARK: - Extensions

extension Data {
    init(hexString: String) throws {
        let hexStr = hexString.dropFirst(hexString.hasPrefix("0x") ? 2 : 0)
        
        guard hexStr.count % 2 == 0 else {
            throw GSAuth.AuthError.invalidData
        }
        
        self.init(capacity: hexStr.count / 2)
        
        var index = hexStr.startIndex
        while index < hexStr.endIndex {
            let byteString = hexStr[index...hexStr.index(after: index)]
            guard let byte = UInt8(byteString, radix: 16) else {
                throw GSAuth.AuthError.invalidData
            }
            self.append(byte)
            index = hexStr.index(index, offsetBy: 2)
        }
    }
    
    func hexEncodedString() -> String {
        self.map { String(format: "%02hhx", $0) }.joined()
    }
}
