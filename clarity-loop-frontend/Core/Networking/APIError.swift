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

    /// Provides a user-friendly description for each error case.
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "There was an issue connecting to the server. (Invalid URL)"
        case .networkError(let urlError):
            return "Network error: \(urlError.localizedDescription)"
        case .serverError(let statusCode, let message):
            if let message = message, !message.isEmpty {
                return "Server error (\(statusCode)): \(message)"
            }
            return "An error occurred on the server (Code: \(statusCode))."
        case .decodingError:
            return "There was an issue processing the response from the server."
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }
} 
 