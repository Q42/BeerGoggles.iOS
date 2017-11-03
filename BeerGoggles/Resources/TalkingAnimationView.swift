//
//  TalkingAnimationView.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class TalkingAnimationView: UIView {

  private let imageView = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  func initialize() {
    backgroundColor = .clear
    addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    imageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    imageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

    let images: [UIImage] = (0...39).map {
      String(format: "%05d", $0)
    }.flatMap {
      Bundle.main.url(forResource: "Moving Talking Head_\($0)", withExtension: "png")
    }.flatMap {
      (try? Data(contentsOf: $0)).map {
        UIImage(data: $0)
      }
    }.flatMap { $0 }.map { $0! }

    imageView.animationImages = images
    imageView.startAnimating()
  }

}

extension UIImage {

  func maskWithColor(color: UIColor) -> UIImage? {
    let maskImage = cgImage!

    let width = size.width
    let height = size.height
    let bounds = CGRect(x: 0, y: 0, width: width, height: height)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!

    context.clip(to: bounds, mask: maskImage)
    context.setFillColor(color.cgColor)
    context.fill(bounds)

    if let cgImage = context.makeImage() {
      let coloredImage = UIImage(cgImage: cgImage)
      return coloredImage
    } else {
      return nil
    }
  }

}
