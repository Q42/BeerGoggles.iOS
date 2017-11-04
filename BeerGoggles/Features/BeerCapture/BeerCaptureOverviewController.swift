//
//  BeerCaptureOverviewController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class BeerCaptureOverviewController: UIViewController {

  private let result: UploadJson
  private let guid: UUID

  @IBOutlet weak private var tableView: UITableView!

  init(result: UploadJson, guid: UUID) {
    self.result = result
    self.guid = guid
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

    let strings = (tableView.indexPathsForSelectedRows ?? []).map {
      self.result.possibles[$0.row]
    }

    let controller = LoadingController(request: .matches(strings: strings, beers: result.matches.map({ $0.beer }), guid: guid))
    navigationController?.pushViewController(controller, animated: true)
  }
}

extension BeerCaptureOverviewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return result.possibles.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.beerSelectCell, for: indexPath) else {
      return UITableViewCell()
    }

    cell.possibility = result.possibles[indexPath.row]

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
