//
//  InsightEndpoint.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation

enum InsightEndpoint {
    case getHistory(userId: String, limit: Int, offset: Int)
    case generate(dto: InsightGenerationRequestDTO)
    case getInsight(id: String)
    case getServiceStatus
}

extension InsightEndpoint: Endpoint {
    var path: String {
        switch self {
        case .getHistory(let userId, _, _):
            return "/api/v1/insights/history/\(userId)"
        case .generate:
            return "/api/v1/insights/generate"
        case .getInsight(let id):
            return "/api/v1/insights/\(id)"
        case .getServiceStatus:
            return "/api/v1/insights/status"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getHistory, .getInsight, .getServiceStatus:
            return .get
        case .generate:
            return .post
        }
    }

    func body(encoder: JSONEncoder) throws -> Data? {
        switch self {
        case .getHistory, .getInsight, .getServiceStatus:
            return nil
        case .generate(let dto):
            return try encoder.encode(dto)
        }
    }
    
    func asURLRequest(baseURL: URL, encoder: JSONEncoder) throws -> URLRequest {
        // First, create the basic request.
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try body(encoder: encoder)
        
        // Then, add query parameters if necessary.
        switch self {
        case .getHistory(_, let limit, let offset):
            guard let url = request.url else {
                throw APIError.invalidURL
            }
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(offset)"),
            ]
            request.url = components?.url
        
        case .generate, .getInsight, .getServiceStatus:
            // These endpoints don't need query parameters
            break
        }
        
        return request
    }
} 
