//
//  SettingsController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class SettingsController: ViewController {

  init() {
    super.init(nibName: "SettingsView", bundle: nil)

    title = "PROFILE"
    tabBarItem = UITabBarItem(title: "PROFILE", image: R.image.profile(), tag: 4)
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

  @IBAction func logoutPressed(_ sender: Any) {
    App.authenticationService.logout()
    AppDelegate.instance.backToRoot()
  }

  @IBAction func howToPressed(_ sender: Any) {
    let controller = HowToController()
    controller.completionHandler = { _ in
      (AppDelegate.instance.window?.rootViewController as? TabController)?.selectedIndex = 0
    }
    present(controller, animated: true, completion: nil)
  }
}
