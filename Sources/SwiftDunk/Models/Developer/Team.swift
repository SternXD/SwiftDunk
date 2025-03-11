//
//  Team.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation

public struct Team: Codable, Identifiable {
    public let id: String
    public let name: String
    public let type: TeamType
    public let status: TeamStatus
    public let memberCount: Int
    public let createdAt: Date
    
    public enum TeamType: String, Codable {
        case individual
        case organization
        case enterprise
    }
    
    public enum TeamStatus: String, Codable {
        case active
        case inactive
        case pendingAgreement = "pending_agreement"
    }
}

public class TeamService {
    private let client: NetworkClient
    
    init(client: NetworkClient) {
        self.client = client
    }
    
    /// Get team details
    /// - Parameter teamId: Team ID to fetch
    /// - Returns: Team details
    public func getTeam(id teamId: String) async throws -> Team {
        return try await client.request("developer/teams/\(teamId)")
    }
    
    /// List all teams
    /// - Returns: List of all teams
    public func listTeams() async throws -> [Team] {
        return try await client.request("developer/teams")
    }
    
    /// Get team members
    /// - Parameter teamId: Team ID
    /// - Returns: List of team members
    public func getTeamMembers(teamId: String) async throws -> [TeamMember] {
        return try await client.request("developer/teams/\(teamId)/members")
    }
}

public struct TeamMember: Codable, Identifiable {
    public let id: String
    public let name: String
    public let email: String
    public let role: Role
    public let status: MemberStatus
    
    public enum Role: String, Codable {
        case admin
        case member
        case owner
    }
    
    public enum MemberStatus: String, Codable {
        case active
        case pending
        case inactive
    }
}