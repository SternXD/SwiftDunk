//
//  AuthService.swift
//  SwiftDunk
//
//  Created by Xavier Stern on 3/10/25.
//


import Foundation

public class AuthService {
    private let client: NetworkClient
    private let gsAuth: GSAuth
    
    init(client: NetworkClient) {
        self.client = client
        self.gsAuth = GSAuth(anisette: Anisette())
    }
    
    /// Authenticate with Apple ID
    /// - Parameters:
    ///   - username: Apple ID username
    ///   - password: Apple ID password
    /// - Returns: Authentication result
    public func authenticate(username: String, password: String) async throws -> Any {
        return try await gsAuth.authenticate(username: username, password: password)
    }
    
    /// Fetch Xcode authentication token
    /// - Parameters:
    ///   - username: Apple ID username
    ///   - password: Apple ID password
    /// - Returns: Xcode session information
    public func fetchXcodeToken(username: String, password: String) async throws -> (Any, Any) {
        return try await gsAuth.fetchXcodeToken(username: username, password: password)
    }
}
