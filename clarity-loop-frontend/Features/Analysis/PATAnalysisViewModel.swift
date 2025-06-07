import Foundation
import Observation

@Observable
final class PATAnalysisViewModel {
    
    // MARK: - Properties
    var analysisState: ViewState<PATAnalysisResult> = .idle
    var isAnalyzing = false
    var errorMessage: String?
    
    private let analyzePATDataUseCase: AnalyzePATDataUseCase
    private let apiClient: APIClientProtocol
    
    // MARK: - Initialization
    init(
        analyzePATDataUseCase: AnalyzePATDataUseCase,
        apiClient: APIClientProtocol
    ) {
        self.analyzePATDataUseCase = analyzePATDataUseCase
        self.apiClient = apiClient
    }
    
    // MARK: - Public Methods
    
    func startStepAnalysis() async {
        await performAnalysis {
            try await self.analyzePATDataUseCase.executeStepAnalysis()
        }
    }
    
    func startCustomAnalysis(for analysisId: String) async {
        analysisState = .loading
        errorMessage = nil
        
        do {
            let response = try await apiClient.getPATAnalysis(id: analysisId)
            let result = PATAnalysisResult(
                analysisId: response.analysisId,
                status: response.status,
                patFeatures: response.patFeatures,
                confidence: response.confidence,
                completedAt: response.completedAt,
                error: response.error
            )
            
            if result.isCompleted {
                analysisState = .loaded(result)
            } else if result.isFailed {
                analysisState = .error(result.error ?? "Analysis failed")
            } else {
                // Still processing, start polling
                await pollForCompletion(analysisId: analysisId)
            }
        } catch {
            analysisState = .error("Failed to fetch analysis: \(error.localizedDescription)")
        }
    }
    
    func retryAnalysis() async {
        await startStepAnalysis()
    }
    
    // MARK: - Private Methods
    
    private func performAnalysis(analysisTask: @escaping () async throws -> PATAnalysisResult) async {
        analysisState = .loading
        isAnalyzing = true
        errorMessage = nil
        
        do {
            let result = try await analysisTask()
            
            if result.isCompleted {
                analysisState = .loaded(result)
            } else if result.isFailed {
                analysisState = .error(result.error ?? "Analysis failed")
            } else if result.isProcessing {
                // Continue polling for completion
                await pollForCompletion(analysisId: result.analysisId)
            }
        } catch {
            let errorMsg = "Analysis failed: \(error.localizedDescription)"
            analysisState = .error(errorMsg)
            errorMessage = errorMsg
        }
        
        isAnalyzing = false
    }
    
    private func pollForCompletion(analysisId: String) async {
        let maxAttempts = 30
        let delaySeconds: UInt64 = 10
        
        for attempt in 1...maxAttempts {
            do {
                let response = try await apiClient.getPATAnalysis(id: analysisId)
                let result = PATAnalysisResult(
                    analysisId: response.analysisId,
                    status: response.status,
                    patFeatures: response.patFeatures,
                    confidence: response.confidence,
                    completedAt: response.completedAt,
                    error: response.error
                )
                
                if result.isCompleted {
                    analysisState = .loaded(result)
                    return
                } else if result.isFailed {
                    analysisState = .error(result.error ?? "Analysis failed")
                    return
                }
                
                // Still processing, wait before next check
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
                }
            } catch {
                if attempt == maxAttempts {
                    analysisState = .error("Failed to get analysis results: \(error.localizedDescription)")
                }
                // Continue polling on errors except for the last attempt
            }
        }
        
        // Timeout
        analysisState = .error("Analysis timed out. Please check back later.")
    }
}

// MARK: - Supporting Types

extension PATAnalysisViewModel {
    var isLoading: Bool {
        switch analysisState {
        case .loading:
            return true
        default:
            return false
        }
    }
    
    var hasError: Bool {
        switch analysisState {
        case .error:
            return true
        default:
            return false
        }
    }
    
    var analysisResult: PATAnalysisResult? {
        switch analysisState {
        case .loaded(let result):
            return result
        default:
            return nil
        }
    }
}