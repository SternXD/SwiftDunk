//
//  AnisetteService.swift
//  SwiftDunk
//
//  Created by SternXD on 3/10/25.
//


import Foundation

public class AnisetteService {
    private let client: NetworkClient
    private let anisette: Anisette
    
    init(client: NetworkClient) {
        self.client = client
        self.anisette = Anisette()
    }
    
    /// Get anisette data required for authentication
    /// - Returns: Anisette headers
    public func getAnisetteData() async throws -> [String: String] {
        return try await anisette.fetchAnisetteData()
    }
    
    /// Get headers for authentication requests
    /// - Parameter includeUser: Whether to include user headers
    /// - Returns: Headers dictionary
    public func getHeaders(includeUser: Bool = false) -> [String: String] {
        return anisette.headers(includeUser: includeUser)
    }
}
