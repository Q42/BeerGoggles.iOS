//
//  ViewController.swift
//  Uncheckd
//
//  Created by Tomas Harkema on 19-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

extension UIViewController {
  fileprivate func fixSafeMargins() {
    if #available(iOS 11, *) {
      // safe area constraints already set
    } else {
      edgesForExtendedLayout = []
    }
  }
}

class ViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    fixSafeMargins()
  }
}

class TableViewController: UITableViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    
    fixSafeMargins()
  }
}
