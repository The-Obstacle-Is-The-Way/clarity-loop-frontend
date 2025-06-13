//
//  CognitoConfiguration.swift
//  clarity-loop-frontend
//
//  Created by Claude on 6/10/2025.
//

import Foundation

struct CognitoConfiguration {
    static let shared = CognitoConfiguration()
    
    // OIDC Configuration from AWS Cognito
    let issuer = "https://cognito-idp.us-east-2.amazonaws.com/us-east-2_iCRM83uVj"
    let clientID = "485gn7vn3uev0coc52aefklkjs"
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