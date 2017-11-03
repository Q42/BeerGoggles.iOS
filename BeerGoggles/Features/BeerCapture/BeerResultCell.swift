//
//  BeerResultCell.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class BeerResultCell: UITableViewCell {

  @IBOutlet weak private var beerNameLabel: UILabel!
  @IBOutlet weak private var breweryLabel: UILabel!

  var beer: BeerJson? {
    didSet {
      backgroundColor = Colors.backgroundColor
      accessoryType = .disclosureIndicator

      beerNameLabel.text = beer?.name
      breweryLabel.text = (beer?.brewery).map { "by \($0)" }
    }
  }

}
