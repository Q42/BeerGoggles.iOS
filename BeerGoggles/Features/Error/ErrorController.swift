//
//  ErrorController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 04-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class ErrorController: UIViewController {

  private let error: Error
  private let retry: (ErrorController) -> Void
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
}
