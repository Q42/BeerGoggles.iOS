//
//  Colors.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

extension UIColor {
  static let tintColor = UIColor(hex: 0xFFCC00)
  static let textColor = UIColor(hex: 0x4A4A4A)
  static let backgroundColor = UIColor(hex: 0x4A4A4A)
  static let barTextColor = UIColor(hex: 0x979797)
}

extension UIColor {

  convenience init(hex: Int) {
    self.init(red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
              green: CGFloat((hex & 0xFF00) >> 8) / 255.0,
              blue: CGFloat(hex & 0xFF) / 255.0,
              alpha: 1)
  }

}
