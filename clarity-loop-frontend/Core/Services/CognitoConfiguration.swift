//
//  CognitoConfiguration.swift
//  clarity-loop-frontend
//
//  Created by Claude on 6/10/2025.
//

import Foundation

struct CognitoConfiguration {
    static let shared = CognitoConfiguration()
    
    // OIDC Configuration from AWS Cognito - PRODUCTION us-east-1
    let issuer = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_1G5jYI8FO"
    let clientID = "66qdivmqgs1oqmmo0b5r9d9hjo"
    let redirectURI = "clarityai://auth"  // Using custom URL scheme for native app
    let logoutURI = "clarityai://logout"
    
    // Cognito endpoints (will be discovered via OIDC)
    var authorizationEndpoint: URL?
    var tokenEndpoint: URL?
    var userInfoEndpoint: URL?
    var endSessionEndpoint: URL?
    
    // OIDC Discovery URL
    var discoveryURL: URL? {
        URL(string: "\(issuer)/.well-known/openid-configuration")
    }
    
    // Scopes requested
    let scopes = ["openid", "profile", "email"]
    
    private init() {}
}