//
//  BeerResultCoordinator.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 09-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

struct BeerResultCoordinator {

  static func controller(for uploadJson: UploadJson, guid: UUID)  -> UIViewController {
    return controller(for: uploadJson.matches, possibles: uploadJson.possibles, guid: guid)
  }

  static func controller(for matches: [MatchesJson], possibles: [String] = [], guid: UUID) -> UIViewController {
    if possibles.isEmpty {
      if matches.isEmpty {
        return BeerEmptyController()
      } else {
        let tapped = matches.filter { $0.user_rating != nil }.map { $0.beer }
        let untapped = matches.filter { $0.user_rating == nil }.map { $0.beer }
        return BeerResultOverviewController(result: .matches(untapped: untapped, tapped: tapped))
      }
    } else {
      return BeerCaptureOverviewController(result: UploadJson(matches: matches, possibles: possibles), guid: guid)
    }
  }

}