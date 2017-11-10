//
//  SettingsController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class SettingsController: UIViewController {

  init() {
    super.init(nibName: "SettingsView", bundle: nil)

    title = "SETTINGS"
    tabBarItem = UITabBarItem(title: "SETTINGS", image: R.image.settings(), tag: 4)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = Colors.backgroundColor
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  @IBAction func logoutPressed(_ sender: Any) {
    App.apiService.logout()
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
