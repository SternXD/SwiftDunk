//
//  NetworkClient.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation

public class NetworkClient {
    private let baseURL: URL
    private var session: URLSession
    private var headers: [String: String] = [:]
    
    /// Initialize client with base URL
    /// - Parameters:
    ///   - baseURL: Base URL for API requests
    ///   - session: URL session (defaults to shared session)
    init(
        baseURL: URL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        
        // Set default headers
        self.headers = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    /// Update authentication token
    /// - Parameter token: Authentication token
    public func setAuthToken(_ token: String) {
        headers["Authorization"] = "Bearer \(token)"
    }
    
    /// Make request to endpoint
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - method: HTTP method
    ///   - parameters: Request parameters
    /// - Returns: Decoded response
    public func request<T: Decodable>(_ endpoint: String,
                                     method: HTTPMethod = .get,
                                     parameters: [String: Any]? = nil) async throws -> T {
        // Create URL
        let url = baseURL.appendingPathComponent(endpoint)
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add parameters
        if let parameters = parameters {
            if method == .get {
                // Add query parameters for GET requests
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
                components?.queryItems = parameters.map {
                    URLQueryItem(name: $0.key, value: "\($0.value)")
                }
                request.url = components?.url
            } else {
                // Add JSON body for other requests
                let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
                request.httpBody = jsonData
            }
        }
        
        // Make request
        let (data, response) = try await session.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Check status code
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        // Decode response
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // HTTP methods
    public enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }
    
    // Network errors
    public enum NetworkError: Error {
        case invalidURL
        case invalidResponse
        case httpError(statusCode: Int, data: Data)
        case decodingError(Error)
    }
}
