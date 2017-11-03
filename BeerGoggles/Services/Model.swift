//
//  Model.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation

struct AuthenticateJson: Decodable {
  let url: URL
}

struct UploadJson: Decodable {
  let magic: String
}
