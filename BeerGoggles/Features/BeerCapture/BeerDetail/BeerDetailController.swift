//
//  BeerDetailController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class BeerDetailController: ViewController {

  private let beer: BeerJson
  @IBOutlet weak private var beerNameLabel: UILabel!
  @IBOutlet weak private var breweryLabel: UILabel!
  @IBOutlet weak private var labelImageView: UIImageView!

  init(beer: BeerJson) {
    self.beer = beer
    super.init(nibName: "BeerDetailView", bundle: nil)
    title = beer.name
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .backgroundColor
    beerNameLabel.text = beer.name
    breweryLabel.text = beer.brewery

    let task = URLSession.shared.dataTask(with: beer.label, completionHandler: { [labelImageView] (data, _, _) in
      DispatchQueue.main.async { [labelImageView] in
        labelImageView?.image = data.flatMap { UIImage(data: $0) }
      }
    })
    task.resume()
  }
  

}
