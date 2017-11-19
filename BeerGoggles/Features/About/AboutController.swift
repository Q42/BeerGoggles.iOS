//
//  AboutController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class AboutController: ViewController {
  init() {
    super.init(nibName: "AboutView", bundle: nil)

    title = "ABOUT"
    tabBarItem = UITabBarItem(title: "TIPS", image: R.image.tips(), tag: 3)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .backgroundColor
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
}
