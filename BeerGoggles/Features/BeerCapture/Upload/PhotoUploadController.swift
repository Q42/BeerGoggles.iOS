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

  @IBOutlet weak private var loadingAnimationView: UIImageView!

  init(file: URL) {
    self.file = file
    super.init(nibName: "PhotoUploadView", bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = Colors.backgroundColor

    animate()

    ApiService.shared.upload(photo: file).then { [navigationController] result in
      print(result)

      var controllers = navigationController?.viewControllers ?? []
      controllers[1] = BeerCaptureOverviewController(beers: result)
      navigationController?.setViewControllers(controllers, animated: true)
    }.trap {
      print($0)
    }
  }

  private func animate() {
    let rotation = CABasicAnimation(keyPath: "transform.rotation")
    rotation.toValue = Double.pi * 2
    rotation.duration = 2
    rotation.repeatCount = HUGE
    loadingAnimationView.layer.add(rotation, forKey: "rotationAnimation")
  }
}
