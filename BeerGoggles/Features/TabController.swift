//
//  TabController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class TabController: UITabBarController {

  override func viewDidLoad() {
    super.viewDidLoad()

    viewControllers = [
      UINavigationController(rootViewController: CameraController()),
      UINavigationController(rootViewController: SessionsController()),
      AboutController(),
      SettingsController()
    ]
  }

}
