//
//  Team.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation

public struct Team: Codable, Sendable {
    public let id: String
    public let name: String
    public let type: TeamType
    public let members: [TeamMember]
    
    public enum TeamType: String, Codable, Sendable {
        case individual
        case organization
        case enterprise
    }
}

public struct TeamMember: Codable, Sendable {
    public let id: String
    public let name: String
    public let email: String
    public let role: Role
    
    public enum Role: String, Codable, Sendable {
        case admin
        case member
        case guest
    }
}

public class TeamService {
    private let client: NetworkClient
    
    init(client: NetworkClient) {
        self.client = client
    }
    
    public func getTeam(id: String) async throws -> Team {
        return try await client.request("teams/\(id)")
    }
    
    public func getTeams() async throws -> [Team] {
        return try await client.request("teams")
    }
    
    public func getTeamMembers(teamId: String) async throws -> [TeamMember] {
        return try await client.request("teams/\(teamId)/members")
    }
    
    public func addTeamMember(teamId: String, email: String, role: TeamMember.Role) async throws -> TeamMember {
        return try await client.request(
            "teams/\(teamId)/members",
            method: .post,
            parameters: [
                "email": email,
                "role": role.rawValue
            ] as [String: String]
        )
    }
    
    public func createTeam(name: String, type: Team.TeamType) async throws -> Team {
        return try await client.request(
            "teams",
            method: .post,
            parameters: [
                "name": name,
                "type": type.rawValue
            ] as [String: String]
        )
    }
}
