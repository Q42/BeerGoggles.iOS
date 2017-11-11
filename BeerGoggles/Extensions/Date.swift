//
//  Date.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 11-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation

extension Date {
  func timeAgoString(to: Date = Date()) -> String {
    let calendar = Calendar.current
    let interval = calendar.dateComponents([.year, .month, .day, .hour], from: self, to: to)
    
    if let year = interval.year, year > 0 {
      return year == 1 ? "\(year)" + " " + "year" :
        "\(year) years ago"
    } else if let month = interval.month, month > 0 {
      return month == 1 ? "\(month)" + " " + "month" :
        "\(month) months ago"
    } else if let day = interval.day, day > 0 {
      return day == 1 ? "\(day) day ago" :
        "\(day) days ago"
    } else {
      return "a moment ago"
    }
  }
}
