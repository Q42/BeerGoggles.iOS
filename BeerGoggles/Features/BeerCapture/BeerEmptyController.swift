//
//  BeerEmptyController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 04-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class BeerEmptyController: UIViewController {
  init() {
    super.init(nibName: "BeerEmptyState", bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
    title = "NO BEERS :("
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = Colors.backgroundColor
  }

  @IBAction func backPressed(_ sender: Any) {
    navigationController?.popViewController(animated: true)
  }

}
