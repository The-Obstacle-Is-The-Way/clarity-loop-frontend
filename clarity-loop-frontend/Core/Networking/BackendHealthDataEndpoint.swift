//
//  BackendHealthDataEndpoint.swift
//  clarity-loop-frontend
//
//  Endpoints for backend-compatible health data uploads
//

import Foundation

enum BackendHealthDataEndpoint {
    case upload(dto: BackendHealthDataUpload)
}

extension BackendHealthDataEndpoint: Endpoint {
    var path: String {
        switch self {
        case .upload:
            return "/api/v1/health-data/upload"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .upload:
            return .post
        }
    }
    
    func body(encoder: JSONEncoder) throws -> Data? {
        switch self {
        case .upload(let dto):
            return try encoder.encode(dto)
        }
    }
}