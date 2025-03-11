//
//  NetworkClient.swift
//  SwiftDunk
//
//  Created by SternXD on 3/9/25.
//


import Foundation
import Alamofire

class NetworkClient {
    private let baseURL: URL
    private let apiKey: String
    private let session: Session
    
    init(baseURL: URL, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        self.session = Session(configuration: configuration)
    }
    
    func request<T: Decodable & Sendable>(
        _ endpoint: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        
        // Default headers including authorization
        var requestHeaders = HTTPHeaders.default
        requestHeaders["Authorization"] = "Bearer \(apiKey)"
        
        // Add custom headers if any
        if let headers = headers {
            headers.forEach { requestHeaders.add($0) }
        }
        
        // Determine encoding based on method
        let encoding: ParameterEncoding = (method == .get) ? URLEncoding.default : JSONEncoding.default
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                url,
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: requestHeaders
            )
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    if let data = response.data {
                        let networkError = NetworkError.serverError(
                            statusCode: response.response?.statusCode ?? 0,
                            data: data
                        )
                        continuation.resume(throwing: networkError)
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

enum NetworkError: Error, Sendable {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, data: Data)
    case decodingError(String)  // Changed from Error to String for Sendable conformance
}
