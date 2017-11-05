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
    
    NotificationCenter.default.addObserver(self, selector: #selector(active), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc func active() {
    if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
      DispatchQueue.main.async {
        AppDelegate.instance.backToRoot()
      }
    }
  }
  
  @IBAction func grantPressed(_ sender: Any) {
    requestAccess()
  }

  private func requestAccess() {
    if AVCaptureDevice.authorizationStatus(for: .video) == .denied {
      UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
      return
    }
    
    AVCaptureDevice.requestAccess(for: .video) { (accept) in
      if accept {
        DispatchQueue.main.async {
          AppDelegate.instance.backToRoot()
        }
      }
    }
  }
}
