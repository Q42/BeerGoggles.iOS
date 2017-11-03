//
//  PhotoUploadController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class PhotoUploadController: UIViewController {
  private let file: URL

  init(file: URL) {
    self.file = file
    super.init(nibName: "PhotoUploadView", bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    ApiService.shared.upload(photo: file).then {
      print($0)
    }.trap {
      print($0)
    }
  }
}
