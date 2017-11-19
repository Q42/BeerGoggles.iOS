//
//  ViewController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import SafariServices
import CancellationToken

class LoginController: ViewController {

  private var cancellationTokenSource: CancellationTokenSource!

  @IBOutlet weak private var aboutButton: ActionButton!

  init() {
    super.init(nibName: "LoginView", bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .backgroundColor
    aboutButton.buttonStyle = .small
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  @IBAction func loginPressed(_ sender: Any) {

    cancellationTokenSource = CancellationTokenSource()

    App.authenticationService.auth()
      .presentLoader(for: self,
                     cancellationTokenSource: cancellationTokenSource,
                     message: .login,
                     handler: { (auth) -> UIViewController in
        SFSafariViewController(url: auth.url)
      })
      .mapError()
      .attachError(for: self, handler: { [weak self] (error) in
        error.dismiss()
        self?.loginPressed(sender)
      })
  }

  private func openLogin(url: URL) {
    let controller = SFSafariViewController(url: url)
    present(controller, animated: true, completion: nil)
  }

  @IBAction func howToPressed(_ sender: Any) {
    let controller = HowToController()
    present(controller, animated: true, completion: nil)
  }
}

