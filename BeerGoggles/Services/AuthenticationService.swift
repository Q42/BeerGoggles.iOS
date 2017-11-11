//
//  AuthenticationService.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 11-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import Promissum
import Valet

struct AuthenticationToken: RawRepresentable {
  let rawValue: String
  init(rawValue: String) {
    self.rawValue = rawValue
  }
}

class AuthenticationService {
  
  private let valet = VALValet(identifier: "io.harkema.BeerGoggles", accessibility: .whenUnlocked)!
  
  private let apiService: ApiService
  private let loginTokenKey = "loginTokenKey"
  
  init(apiService: ApiService) {
    self.apiService = apiService
  }
  
  func migrate() {
    if let token = UserDefaults.standard.string(forKey: loginTokenKey), !valet.containsObject(forKey: loginTokenKey) {
      valet.setString(token, forKey: loginTokenKey)
      UserDefaults.standard.removeObject(forKey: loginTokenKey)
    }
  }

  private func loginToken() -> AuthenticationToken? {
    return valet.string(forKey: loginTokenKey).map { AuthenticationToken(rawValue: $0) }
  }
  
  func isLoggedIn() -> Bool {
    return loginToken() != nil
  }
  
  func login(with token: AuthenticationToken) {
    valet.setString(token.rawValue, forKey: loginTokenKey)
  }
  
  func logout() {
    valet.removeObject(forKey: loginTokenKey)
  }
  
  func auth() -> Promise<AuthenticateJson, ApiError> {
    return apiService.auth()
  }
  
  func wrapAuthenticate<PromiseValueType>(_ handler: (AuthenticationToken) -> Promise<PromiseValueType, ApiError>) -> Promise<PromiseValueType, ApiError> {
    if let token = loginToken() {
      return handler(token)
    } else {
      return Promise(error: ApiError.notLoggedIn)
    }
  }
}
