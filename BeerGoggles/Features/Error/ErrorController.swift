//
//  ErrorController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 04-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import Promissum

class ErrorController: UIViewController {
  typealias ErrorClosure = (ErrorController) -> Void

  private let error: Error
  private let retry: ErrorClosure
  @IBOutlet weak var errorLabel: UILabel!

  init(error: Error, retry: @escaping (ErrorController) -> Void) {
    self.error = error
    self.retry = retry
    super.init(nibName: "ErrorView", bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = Colors.backgroundColor
    errorLabel.text = error.localizedDescription
  }
  
  @IBAction func tryAgainPressed(_ sender: Any) {
    retry(self)
  }

  func dismiss() {
    if let navigationController = navigationController {
      navigationController.popViewController(animated: true)
    } else {
      dismiss(animated: true, completion: nil)
    }
  }
}

extension Promise where Error == Swift.Error {
  func attachError(for controller: UIViewController, handler: @escaping ErrorController.ErrorClosure) -> Promise<Value, Error> {
    return self.trap {
      let errorController = ErrorController(error: $0, retry: handler)

      if let navigationController = controller.navigationController {
        let index = navigationController.viewControllers.index { $0 is LoadingController } ?? 0

        var controllers = navigationController.viewControllers
        controllers[index] = errorController
        navigationController.setViewControllers(controllers, animated: true)
      } else {
        controller.present(errorController, animated: true, completion: nil)
      }
    }
  }
}
