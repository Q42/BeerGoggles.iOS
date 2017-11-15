//
//  App.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 09-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation

struct App {
  static let apiService = ApiService()
  static let authenticationService = AuthenticationService(apiService: apiService)
  static let databaseService = DatabaseService()
  static let imageService = ImageService(apiService: apiService, databaseService: databaseService, authenticationService: authenticationService)
}
