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
  let bid: Int?
  let name: String
  let brewery: String
  let full_name: String
  let abv: Float
  let ibu: Int
  let style: String
  let description: String
  let label: URL
  let rating_score: Float?
}

struct Session {
  let captureDate: Date
  let imageGuid: UUID
  let beers: [BeerJson]

  init?(model: SessionModel) {

    guard let captureDate = model.captureDate,
      let imageGuid = model.imageGuid,
      let beers = model.beers as? Set<BeerModel>
      else {
        return nil
      }

    self.captureDate = captureDate
    self.imageGuid = imageGuid
    self.beers = beers.flatMap { (beer: BeerModel) -> BeerJson? in

      guard let name = beer.name,
        let brewery = beer.brewery,
        let full_name = beer.full_name,
        let style = beer.style,
        let description = beer.beerDescription,
        let label = beer.label
        else {
          return nil
        }

      return BeerJson(id: Int(beer.id),
               bid: Int(beer.bid),
               name: name,
               brewery: brewery,
               full_name: full_name,
               abv: beer.abv,
               ibu: Int(beer.ibu),
               style: style,
               description: description,
               label: label,
               rating_score: beer.rating_score)
    }
  }
}
