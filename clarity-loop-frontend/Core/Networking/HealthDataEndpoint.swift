//
//  HealthDataEndpoint.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation

enum HealthDataEndpoint {
    case getMetrics(page: Int, limit: Int)
}

extension HealthDataEndpoint: Endpoint {
    var path: String {
        switch self {
        case .getMetrics:
            return "/health-data"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getMetrics:
            return .get
        }
    }

    func body(encoder: JSONEncoder) throws -> Data? {
        // GET requests typically don't have a body.
        return nil
    }
    
    // We can extend this to handle query parameters.
    func asURLRequest(baseURL: URL, encoder: JSONEncoder) throws -> URLRequest {
        var request = try Endpoint.super.asURLRequest(baseURL: baseURL, encoder: encoder)
        
        switch self {
        case .getMetrics(let page, let limit):
            guard let url = request.url else { break }
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)"),
            ]
            request.url = components?.url
        }
        
        return request
    }
} 
