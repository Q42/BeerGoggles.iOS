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
  @IBOutlet weak private var breweryLabel: UILabel!
  @IBOutlet weak private var selectIcon: UIImageView!

  var beer: BeerJson? {
    didSet {
      selectionStyle = .none
      backgroundColor = Colors.backgroundColor
      nameLabel.text = beer?.name
      breweryLabel.text = (beer?.brewery).map { "by \($0)" }
    }
  }

  override var isSelected: Bool {
    didSet {
      selectIcon.image = isSelected ? R.image.selected() : R.image.unselected()
    }
  }

}
