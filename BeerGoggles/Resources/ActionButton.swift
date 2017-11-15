//
//  ActionButton.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class ActionButton: UIButton {

  enum Style {
    case `default`
    case small
//    case destructive
//    case notice

    var insets: UIEdgeInsets {
      switch self {
      case .default:
        return UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
      case .small:
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
      }
    }

    var titleColor: UIColor {
      switch self {
      case .default:
        return .textColor
      case .small:
        return .tintColor
      }
    }

    var backgroundColor: UIColor {
      switch self {
      case .default:
        return .tintColor
      case .small:
        return .clear
      }
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    initialize()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

    initialize()
  }

  override func prepareForInterfaceBuilder() {
    super.prepareForInterfaceBuilder()

    initialize()
  }

  var buttonStyle = Style.default {
    didSet {
      initialize()
    }
  }

  func initialize() {
    backgroundColor = buttonStyle.backgroundColor
    setTitleColor(buttonStyle.titleColor, for: .normal)
    titleLabel?.font = Fonts.futuraBold(with: 16)
    titleLabel?.numberOfLines = 0

    contentEdgeInsets = buttonStyle.insets
    layer.cornerRadius = 4
  }

  override var isEnabled: Bool {
    didSet {
      let color = isEnabled ? buttonStyle.titleColor : UIColor.lightGray
      setTitleColor(color, for: .normal)
    }
  }
}
