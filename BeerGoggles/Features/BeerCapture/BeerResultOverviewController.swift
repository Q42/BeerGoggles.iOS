//
//  BeerResultOverviewController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class BeerResultOverviewController: UITableViewController {

  enum Result {
    case beers(beers: [BeerJson])
    case matches(untapped: [BeerJson], tapped: [BeerJson])
  }

  private let result: Result

  init(result: Result) {
    self.result = result
    super.init(style: .plain)

    title = "BEERS!"
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.register(R.nib.beerResultCell)
    tableView.backgroundColor = Colors.backgroundColor
    tableView.rowHeight = 105
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    switch result {
    case .beers:
      return 1
    case .matches:
      return 2
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

    switch result {
    case .beers(let beers):
      return beers.count
    case .matches(let untapped, let tapped):
      if section == 1 {
        return tapped.count
      } else {
        return untapped.count
      }
    }
  }

  private func beer(for indexPath: IndexPath) -> BeerJson {
    switch result {
    case .beers(let beers):
      return beers[indexPath.row]
    case .matches(let untapped, let tapped):
      if indexPath.section == 1 {
        return tapped[indexPath.row]
      } else {
        return untapped[indexPath.row]
      }
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.beerResultCell, for: indexPath) else {
      return UITableViewCell()
    }

    cell.beer = beer(for: indexPath)

    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let controller = BeerDetailController(beer: beer(for: indexPath))
    navigationController?.pushViewController(controller, animated: true)
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

    switch result {
    case .beers:
      return nil
    case .matches:
      if section == 1 {
        return "tapped"
      } else {
        return "untapped"
      }
    }
  }

}
