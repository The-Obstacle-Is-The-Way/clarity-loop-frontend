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
            return "/pat/analyze/steps"
        case .analyzeActigraphy:
            return "/pat/analyze/actigraphy"
        case .getAnalysis(let id):
            return "/pat/analysis/\(id)"
        case .getServiceHealth:
            return "/pat/health"
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