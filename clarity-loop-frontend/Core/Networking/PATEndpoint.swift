import Foundation

enum PATEndpoint {
    case analyzeStepData(dto: StepDataRequestDTO)
    case analyzeActigraphy(dto: DirectActigraphyRequestDTO)
    case getAnalysis(id: String)
    case getServiceHealth
}

extension PATEndpoint: Endpoint {
    var path: String {
        switch self {
        case .analyzeStepData:
            return "/api/v1/pat/analyze-step-data"
        case .analyzeActigraphy:
            return "/api/v1/pat/analyze"
        case .getAnalysis(let id):
            return "/api/v1/pat/analysis/\(id)"
        case .getServiceHealth:
            return "/api/v1/pat/health"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .analyzeStepData, .analyzeActigraphy:
            return .post
        case .getAnalysis, .getServiceHealth:
            return .get
        }
    }

    func body(encoder: JSONEncoder) throws -> Data? {
        switch self {
        case .analyzeStepData(let dto):
            return try encoder.encode(dto)
        case .analyzeActigraphy(let dto):
            return try encoder.encode(dto)
        case .getAnalysis, .getServiceHealth:
            return nil
        }
    }
}