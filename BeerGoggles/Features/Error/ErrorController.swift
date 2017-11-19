//
//  ErrorController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 04-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import Promissum

class ErrorController: ViewController {
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
    view.backgroundColor = .backgroundColor
    errorLabel.text = (error as? ApiError)?.localizedDescription ?? (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    
    print("Present error: \(error)")
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
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
  @discardableResult
  func attachError(for controller: UIViewController, handler: @escaping ErrorController.ErrorClosure) -> Promise<Value, Error> {
    return self.trap { error in
      if let apiError = error as? ApiError, case .cancelled = apiError {
        return
      }

      let errorController = ErrorController(error: error, retry: handler)

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
