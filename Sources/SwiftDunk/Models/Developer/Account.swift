//
//  Account.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation

public struct Account: Codable, Identifiable {
    public let id: String
    public let name: String
    public let email: String
    public let roles: [Role]
    public let status: AccountStatus
    public let teamIds: [String]
    public let createdAt: Date
    public let updatedAt: Date
    
    public enum AccountStatus: String, Codable {
        case active
        case inactive
        case pending
    }
    
    public struct Role: Codable {
        public let name: String
        public let permissions: [String]
    }
}

public class AccountService {
    private let client: NetworkClient
    
    init(client: NetworkClient) {
        self.client = client
    }
    
    /// Get account details
    /// - Parameter accountId: Account ID to fetch
    /// - Returns: Account details
    public func getAccount(id accountId: String) async throws -> Account {
        return try await client.request("developer/accounts/\(accountId)")
    }
    
    /// Get current user account
    /// - Returns: Current user account details
    public func getCurrentAccount() async throws -> Account {
        return try await client.request("developer/accounts/me")
    }
    
    /// List all accounts
    /// - Returns: List of all accounts
    public func listAccounts() async throws -> [Account] {
        return try await client.request("developer/accounts")
    }
}