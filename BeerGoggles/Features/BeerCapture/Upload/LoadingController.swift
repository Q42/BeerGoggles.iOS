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
import CancellationToken

final class LoadingController: UIViewController {

  private let cancellationTokenSource: CancellationTokenSource

  @IBOutlet weak private var cancelButton: ActionButton!

  init(cancellationTokenSource: CancellationTokenSource) {
    self.cancellationTokenSource = cancellationTokenSource
    super.init(nibName: R.nib.loadingView.name, bundle: R.nib.loadingView.bundle)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    cancelButton.buttonStyle = .small
    navigationItem.hidesBackButton = true
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    cancellationTokenSource.cancel()
  }
  
  @IBAction func cancelButtonPressed(_ sender: Any) {
    cancellationTokenSource.cancel()
    navigationController?.popViewController(animated: true)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
}

extension Promise {
  func presentLoader(for controller: UIViewController, cancellationTokenSource: CancellationTokenSource, handler: @escaping (Value) -> UIViewController) -> Promise<Value, Error> {

    let loadingController = LoadingController(cancellationTokenSource: cancellationTokenSource)

    if let navigationController = controller.navigationController {
      navigationController.pushViewController(loadingController, animated: true)
    } else {
      controller.present(loadingController, animated: true, completion: nil)
    }

    return self.delay(1).then { [weak loadingController] result in
      if cancellationTokenSource.token.isCancellationRequested {
        return
      }

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
      if cancellationTokenSource.token.isCancellationRequested {
        return
      }
      
      if let navigationController = controller.navigationController {
//        navigationController.popViewController(animated: true)
      } else {
        loadingController?.dismiss(animated: true, completion: nil)
      }
    }
  }
}
