//
//  HealthDataEndpoint.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation

enum HealthDataEndpoint {
    case getMetrics(page: Int, limit: Int)
    case uploadHealthKit(dto: HealthKitUploadRequestDTO)
    case syncHealthKit(dto: HealthKitSyncRequestDTO)
    case getSyncStatus(syncId: String)
    case getUploadStatus(uploadId: String)
    case getProcessingStatus(id: UUID)
}

extension HealthDataEndpoint: Endpoint {
    var path: String {
        switch self {
        case .getMetrics:
            return "/health-data"
        case .uploadHealthKit:
            return "/health-data/upload"
        case .syncHealthKit:
            return "/health-data/sync"
        case .getSyncStatus(let syncId):
            return "/health-data/sync/\(syncId)"
        case .getUploadStatus(let uploadId):
            return "/health-data/upload/\(uploadId)/status"
        case .getProcessingStatus(let id):
            return "/health-data/processing/\(id.uuidString)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getMetrics, .getSyncStatus, .getUploadStatus, .getProcessingStatus:
            return .get
        case .uploadHealthKit, .syncHealthKit:
            return .post
        }
    }

    func body(encoder: JSONEncoder) throws -> Data? {
        switch self {
        case .getMetrics, .getSyncStatus, .getUploadStatus, .getProcessingStatus:
            return nil
        case .uploadHealthKit(let dto):
            return try encoder.encode(dto)
        case .syncHealthKit(let dto):
            return try encoder.encode(dto)
        }
    }
    
    // We can extend this to handle query parameters.
    func asURLRequest(baseURL: URL, encoder: JSONEncoder) throws -> URLRequest {
        // First, create the basic request.
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try body(encoder: encoder)
        
        // Then, add query parameters if necessary.
        switch self {
        case .getMetrics(let page, let limit):
            guard let url = request.url else {
                throw APIError.invalidURL
            }
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)"),
            ]
            request.url = components?.url
        case .uploadHealthKit, .syncHealthKit, .getSyncStatus, .getUploadStatus, .getProcessingStatus:
            // These endpoints don't need query parameters
            break
        }
        
        return request
    }
} 
