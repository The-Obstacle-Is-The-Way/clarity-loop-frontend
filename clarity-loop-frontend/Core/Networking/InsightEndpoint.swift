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
}

extension InsightEndpoint: Endpoint {
    var path: String {
        switch self {
        case .getHistory(let userId, _, _):
            return "/insights/history/\(userId)"
        case .generate:
            return "/insights/generate"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getHistory:
            return .get
        case .generate:
            return .post
        }
    }

    func body(encoder: JSONEncoder) throws -> Data? {
        switch self {
        case .getHistory:
            return nil
        case .generate(let dto):
            return try encoder.encode(dto)
        }
    }
    
    func asURLRequest(baseURL: URL, encoder: JSONEncoder) throws -> URLRequest {
        var request = try Endpoint.super.asURLRequest(baseURL: baseURL, encoder: encoder)
        
        switch self {
        case .getHistory(_, let limit, let offset):
            guard let url = request.url else { break }
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(offset)"),
            ]
            request.url = components?.url
        
        case .generate:
            // The body is already handled in the `body(encoder:)` function.
            break
        }
        
        return request
    }
} 
