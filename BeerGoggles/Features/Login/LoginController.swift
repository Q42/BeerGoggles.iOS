//
//  ViewController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import SafariServices

class LoginController: UIViewController {

  init() {
    super.init(nibName: "LoginView", bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = Colors.backgroundColor
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  @IBAction func loginPressed(_ sender: Any) {
    ApiService.shared.auth().then { [weak self] result in
      self?.openLogin(url: result.url)
    }.trap {
      print($0)
    }
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

