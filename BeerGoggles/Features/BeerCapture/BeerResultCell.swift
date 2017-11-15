//
//  BeerResultCell.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class BeerResultCell: UITableViewCell {

  struct ViewModel {
    let beer: BeerJson
    let uncheckd: Bool
  }

  @IBOutlet weak private var beerNameLabel: UILabel!
  @IBOutlet weak private var breweryLabel: UILabel!
  @IBOutlet weak private var checkedView: UIImageView!

  var viewModel: ViewModel? {
    didSet {
      backgroundColor = .backgroundColor
//      accessoryType = .disclosureIndicator

      beerNameLabel.text = viewModel?.beer.name
      breweryLabel.text = (viewModel?.beer.brewery).map { "by \($0)" }
      checkedView.isHidden = viewModel?.uncheckd == false
    }
  }

}
