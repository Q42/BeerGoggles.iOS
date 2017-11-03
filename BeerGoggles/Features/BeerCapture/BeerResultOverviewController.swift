//
//  BeerResultOverviewController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class BeerResultOverviewController: UITableViewController {

  private let matches: [MatchesJson]

  init(matches: [MatchesJson]) {
    self.matches = matches
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
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
    return matches.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.beerResultCell, for: indexPath) else {
      return UITableViewCell()
    }
    cell.beer = matches[indexPath.row].beer
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let controller = BeerDetailController(beer: matches[indexPath.row].beer)
    navigationController?.pushViewController(controller, animated: true)
  }

}
