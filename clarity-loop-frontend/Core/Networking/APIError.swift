import Foundation

/// Defines the comprehensive set of errors that can occur within the networking layer.
enum APIError: Error, LocalizedError {
    /// The URL could not be formed. This is a client-side programming error.
    case invalidURL

    /// An error occurred during the network request, wrapping the underlying `URLError`.
    case networkError(URLError)

    /// The server responded with a non-2xx status code.
    /// Includes the status code and an optional descriptive message from the server.
    case serverError(statusCode: Int, message: String?)

    /// The response data could not be decoded into the expected type.
    /// Wraps the underlying decoding error.
    case decodingError(Error)

    /// The request was unauthorized (401). This typically means the session token is invalid or expired.
    case unauthorized

    /// An unknown or uncategorized error occurred.
    case unknown(Error)
    
    /// Functionality not yet implemented (for mocks and testing).
    case notImplemented
    
    /// Validation error for invalid input data
    case validationError(String)

    /// Provides a user-friendly description for each error case.
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Server error \(statusCode): \(message ?? "No message")"
        case .decodingError:
            return "There was a problem decoding the data from the server."
        case .unauthorized:
            return "You are not authorized. Please log in again."
        case .unknown:
            return "An unknown error occurred."
        case .notImplemented:
            return "This functionality is not yet implemented."
        case .validationError(let message):
            return "Validation error: \(message)"
        }
    }
} 
 
