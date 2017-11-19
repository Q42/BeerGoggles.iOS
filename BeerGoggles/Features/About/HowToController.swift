//
//  HowToController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 04-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class HowToController: ViewController {
  
  var completionHandler: ((HowToController) -> Void)?
  
  init() {
    super.init(nibName: "HowToView", bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @IBAction func dismissPressed(_ sender: Any) {
    dismiss(animated: true) { [weak self] in
      guard let controller = self else {
        return
      }
      controller.completionHandler?(controller)
    }
  }
}
