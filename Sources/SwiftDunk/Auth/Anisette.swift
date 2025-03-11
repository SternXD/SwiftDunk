//
//  Anisette.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation

public class Anisette {
    private let baseURL: URL?
    private let serial: String?
    private let urlSession: URLSession
    
    // The client provisioning data
    public private(set) var cpd: [String: Any] = [:]
    private var anisetteData: [String: String] = [:]
    
    /// Initialize Anisette service
    /// - Parameters:
    ///   - url: Optional anisette server URL
    ///   - serial: Optional device serial number
    ///   - urlSession: Optional URL session
    public init(url: String? = nil, serial: String? = nil, urlSession: URLSession? = nil) {
        self.baseURL = url != nil ? URL(string: url!) : nil
        self.serial = serial
        self.urlSession = urlSession ?? URLSession.shared
        
        // Initialize CPD with default values
        self.cpd = [
            "bootstrap": true,
            "icscrec": true,
            "pbe": false,
            "prkgen": true,
            "svct": "iCloud"
        ]
        
        // Initialize with empty anisette data - would be fetched from server when needed
        self.anisetteData = [:]
    }
    
    /// Get anisette headers
    /// - Parameter includeUser: Whether to include user-related headers
    /// - Returns: Dictionary of headers
    public func headers(includeUser: Bool = false) -> [String: String] {
        // This is simplified - in a real implementation you would fetch from your anisette server
        // or implement the native anisette generation on macOS
        return [
            "X-Apple-I-MD": anisetteData["X-Apple-I-MD"] ?? "",
            "X-Apple-I-MD-M": anisetteData["X-Apple-I-MD-M"] ?? "",
            "X-Apple-I-MD-RINFO": anisetteData["X-Apple-I-MD-RINFO"] ?? "",
            "X-Apple-I-SRL-NO": anisetteData["X-Apple-I-SRL-NO"] ?? ""
        ]
    }
    
    /// Fetch anisette data from server
    /// - Returns: Anisette data dictionary
    public func fetchAnisetteData() async throws -> [String: String] {
        guard let url = baseURL else {
            throw AnisetteError.missingServerURL
        }
        
        var request = URLRequest(url: url.appendingPathComponent("/anisette/data"))
        if let serial = serial {
            request.addValue(serial, forHTTPHeaderField: "X-Apple-Serial")
        }
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AnisetteError.requestFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let headers = json["anisette-headers"] as? [String: String] else {
            throw AnisetteError.invalidResponse
        }
        
        anisetteData = headers
        return headers
    }
}

/// Anisette errors
public enum AnisetteError: Error {
    case missingServerURL
    case requestFailed(statusCode: Int)
    case invalidResponse
}