//
//  AnimationView.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class AnimationView: UIView {
  private let imageView = UIImageView()

  private static let cache = NSCache<NSString, NSArray>()

  func initialize(name: String, max: Int) {
    backgroundColor = .clear
    addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    imageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    imageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

    if let images = AnimationView.cache.object(forKey: name as NSString) {
      imageView.animationImages = images as? [UIImage]
    } else {
      let images: [UIImage] = (0...max).map {
        String(format: "%05d", $0)
      }.flatMap {
        Bundle.main.url(forResource: "\(name)_\($0)", withExtension: "png")
      }.flatMap {
        (try? Data(contentsOf: $0)).map {
          UIImage(data: $0)
        }
      }.flatMap { $0 }.map { $0! }
      imageView.animationImages = images
      AnimationView.cache.setObject(images as NSArray, forKey: name as NSString)
    }

    imageView.startAnimating()
  }
}

class TalkingAnimationView: AnimationView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize(name: "Moving Talking Head", max: 39)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize(name: "Moving Talking Head", max: 39)
  }
}

class LoadingAnimationView: AnimationView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize(name: "Loading Skull", max: 39)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize(name: "Loading Skull", max: 39)
  }
}

