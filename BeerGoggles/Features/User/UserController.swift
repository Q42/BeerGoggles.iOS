//
//  UserController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class UserController: UIViewController {

  init() {
    super.init(nibName: "UserView", bundle: nil)
    title = "User"
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @IBAction func logoutPressed(_ sender: Any) {
    ApiService.shared.logout()
    AppDelegate.instance.backToRoot()
  }
}
