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

final class LoadingController: ViewController {

  enum Message {
    case scanning
    case login
    
    var string: String {
      switch self {
      case .scanning:
        return "Looking for beers in your scan…"
      case .login:
        return "Contacting Untappd…"
      }
    }
  }

  private let cancellationTokenSource: CancellationTokenSource
  private let message: Message

  @IBOutlet weak private var cancelButton: ActionButton!
  @IBOutlet weak private var loadingTextView: UILabel!

  init(cancellationTokenSource: CancellationTokenSource, message: Message) {
    self.cancellationTokenSource = cancellationTokenSource
    self.message = message
    super.init(nibName: R.nib.loadingView.name, bundle: R.nib.loadingView.bundle)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    cancelButton.buttonStyle = .small
    navigationItem.hidesBackButton = true
    loadingTextView.text = message.string

    cancellationTokenSource.register { [weak self, navigationController] in
      if let navigationController = navigationController {
        navigationController.popViewController(animated: true)
      } else {
        self?.dismiss(animated: true, completion: nil)
      }
    }
  }
  
  @IBAction func cancelButtonPressed(_ sender: Any) {
    cancellationTokenSource.cancel()
    dismiss(animated: true, completion: nil)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
}

extension Promise {
  func presentLoader(for controller: UIViewController, cancellationTokenSource: CancellationTokenSource, message: LoadingController.Message, handler: @escaping (Value) -> UIViewController) -> Promise<Value, Error> {

    let loadingController = LoadingController(cancellationTokenSource: cancellationTokenSource, message: message)

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
    }
  }
}
