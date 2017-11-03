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
  let matches: [MatchesJson]
  let possibles: [String]
}

struct MatchesJson: Decodable {
  let user_rating: Float?
  let wish_list: Bool?
  let beer: BeerJson
}

struct BeerJson: Decodable {
  let id: Int
  let bid: Int
  let name: String
  let brewery: String
  let full_name: String
  let abv: Float
  let ibu: Int
  let style: String
  let description: String
  let label: URL
  let rating_score: Float
}
