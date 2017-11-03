//
//  BeerCaptureOverviewController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class BeerCaptureOverviewController: UIViewController {

  private let matches: [MatchesJson]

  @IBOutlet weak private var tableView: UITableView!

  init(matches: [MatchesJson]) {
    self.matches = matches
    super.init(nibName: "BeerCaptureOverviewView", bundle: nil)
    title = "BEERS...?"
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = Colors.backgroundColor

    tableView.dataSource = self
    tableView.delegate = self
    tableView.backgroundColor = Colors.backgroundColor
    tableView.register(R.nib.beerSelectCell)
    tableView.rowHeight = 70
    tableView.allowsSelection = true
    tableView.allowsMultipleSelection = true
  }

  @IBAction func nextPressed(_ sender: Any) {
    let controller = BeerResultOverviewController(matches: matches)
    navigationController?.pushViewController(controller, animated: true)
  }
}

extension BeerCaptureOverviewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return matches.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.beerSelectCell, for: indexPath) else {
      return UITableViewCell()
    }

    cell.beer = matches[indexPath.row].beer

    return cell
  }
}

extension BeerCaptureOverviewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath)
    cell?.isSelected = true
  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath)
    cell?.isSelected = false
  }
}
