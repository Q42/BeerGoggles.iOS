//
//  BeerCaptureOverviewController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class BeerCaptureOverviewController: UIViewController {
  init() {
    super.init(nibName: "BeerCaptureOverviewView", bundle: nil)
    title = "Beers"
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
