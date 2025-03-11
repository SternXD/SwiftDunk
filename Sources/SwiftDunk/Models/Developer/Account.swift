//
//  Account.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation

public struct Account: Codable, Sendable {
    public let id: String
    public let name: String
    public let email: String
    public let status: Status
    public let roles: [Role]
    
    public enum Status: String, Codable, Sendable {
        case active
        case invited
        case inactive
    }
    
    public enum Role: String, Codable, Sendable {
        case admin
        case developer
        case marketing
        case finance
    }
}

public class AccountService {
    private let client: NetworkClient
    
    init(client: NetworkClient) {
        self.client = client
    }
    
    public func getAccount(id: String) async throws -> Account {
        return try await client.request("accounts/\(id)")
    }
    
    public func getAccounts() async throws -> [Account] {
        return try await client.request("accounts")
    }
    
    public func createAccount(name: String, email: String) async throws -> Account {
        return try await client.request(
            "accounts",
            method: .post,
            parameters: ["name": name, "email": email]
        )
    }
}
