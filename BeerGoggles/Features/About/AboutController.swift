//
//  AboutController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class AboutController: UIViewController {
  init() {
    super.init(nibName: "AboutView", bundle: nil)

    title = "ABOUT"
    tabBarItem = UITabBarItem(title: "ABOUT", image: R.image.about(), tag: 3)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}