//
//  AuthorizationController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import AVKit

class AuthorizationController: UIViewController {

  init() {
    super.init(nibName: "AuthorizationView", bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = Colors.backgroundColor

    
  }
  @IBAction func grantPressed(_ sender: Any) {
    AVCaptureDevice.requestAccess(for: AVMediaType.video) { (accept) in
      print(accept)
    }
  }
}
