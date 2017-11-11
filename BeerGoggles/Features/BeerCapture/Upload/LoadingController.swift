//
//  PhotoUploadController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import Promissum
import AVKit

final class LoadingController: UIViewController {
  @IBOutlet weak private var loadingAnimationView: UIImageView!

  init() {
    super.init(nibName: R.nib.loadingView.name, bundle: R.nib.loadingView.bundle)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = Colors.backgroundColor
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    animate()
  }

  private func animate() {
    let rotation = CABasicAnimation(keyPath: "transform.rotation")
    rotation.toValue = Double.pi * 2
    rotation.duration = 2
    rotation.repeatCount = HUGE
    loadingAnimationView.layer.add(rotation, forKey: "rotationAnimation")
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    if navigationController != nil {
      return .default
    } else {
      return .lightContent
    }
  }
}

extension Promise {
  func presentLoader(for controller: UIViewController, handler: @escaping (Value) -> UIViewController) -> Promise<Value, Error> {

    let loadingController = LoadingController()

    if let navigationController = controller.navigationController {
      navigationController.pushViewController(loadingController, animated: true)
    } else {
      controller.present(loadingController, animated: true, completion: nil)
    }

    return self.delay(1).then { [weak loadingController] result in
      if let navigationController = controller.navigationController {
        let index = navigationController.viewControllers.index { $0 is LoadingController } ?? 0

        var controllers = navigationController.viewControllers
        controllers[index] = handler(result)
        navigationController.setViewControllers(controllers, animated: true)

      } else {
        loadingController?.dismiss(animated: true) {
          controller.present(handler(result), animated: true, completion: nil)
        }
      }
    }.trap { [weak loadingController] _ in
      if let navigationController = controller.navigationController {
//        navigationController.popViewController(animated: true)
      } else {
        loadingController?.dismiss(animated: true, completion: nil)
      }
    }
  }
}
