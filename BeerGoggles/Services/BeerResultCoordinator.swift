//
//  BeerResultCoordinator.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 09-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

struct BeerResultCoordinator {

  static func controller(for uploadJson: UploadJson, identifier: SessionIdentifier)  -> UIViewController {
    return controller(for: uploadJson.matches, possibles: uploadJson.possibles, identifier: identifier)
  }

  static let forceAnswer = true

  static func controller(for matches: [BeerJson], possibles: [String] = [], identifier: SessionIdentifier) -> UIViewController {
    if possibles.isEmpty || forceAnswer {
      if matches.isEmpty {
        return BeerEmptyController()
      } else {
        let tapped = matches //[BeerJson]() //.filter { $0.user_rating != nil }.flatMap { $0.beer }
        let untapped = matches // matches.filter { $0.user_rating == nil }.flatMap { $0.beer }
        return BeerResultOverviewController(result: .matches(untapped: untapped, tapped: tapped))
      }
    } else {
      return BeerCaptureOverviewController(result: UploadJson(matches: matches, possibles: possibles), sessionIdentifier: identifier)
    }
  }

}
