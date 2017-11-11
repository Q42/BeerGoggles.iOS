//
//  SessionCell.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 11-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class SessionCell: UITableViewCell {
  
  @IBOutlet weak private var title: UILabel!
  @IBOutlet weak private var amount: UILabel!
  @IBOutlet weak private var thumbnail: UIImageView!
  
  var session: Session? {
    didSet {
      guard let session = session else{
        return
      }
      
      title.text = session.captureDate.timeAgoString()
      amount.text = "\(session.beers.count) beers scanned"
      
      thumbnail.image = nil
      
      let fileOptional = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        .first
        .flatMap { URL(string: $0) }?
        .appendingPathComponent("\(session.imageGuid).jpg")
      
      DispatchQueue.global().async { [thumbnail] in
        if let file = fileOptional {
          let data = FileManager.default.contents(atPath: file.absoluteString)
          let image = data.flatMap { UIImage(data: $0) }
          DispatchQueue.main.async { [thumbnail] in
            thumbnail?.image = image
          }
        }
      }
    }
  }
}
