//
//  BeerSelectCell.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class BeerSelectCell: UITableViewCell {
  
  @IBOutlet weak private var nameLabel: UILabel!
  @IBOutlet weak private var selectIcon: UIImageView!

  var possibility: String? {
    didSet {
      selectionStyle = .none
      backgroundColor = Colors.backgroundColor
      nameLabel.text = possibility
//      breweryLabel.text = (beer?.brewery).map { "by \($0)" }
    }
  }

  override var isSelected: Bool {
    didSet {
      selectIcon.image = isSelected ? R.image.selected() : R.image.unselected()
    }
  }

}
