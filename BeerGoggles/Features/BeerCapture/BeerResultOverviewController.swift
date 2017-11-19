//
//  BeerResultOverviewController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class BeerResultOverviewController: ViewController, UITableViewDelegate, UITableViewDataSource {

  enum Result {
    case beers(beers: [BeerJson])
    case matches(untapped: [BeerJson], tapped: [BeerJson])
  }

  private let result: Result
  @IBOutlet weak private var tableView: UITableView!
  @IBOutlet weak private var countLabel: UILabel!

  init(result: Result) {
    self.result = result
    super.init(nibName: R.nib.beerResultOverview.name, bundle: R.nib.beerResultOverview.bundle)

    title = "BEERS FOUND"
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.delegate = self
    tableView.dataSource = self

    tableView.register(R.nib.beerResultCell)
    tableView.backgroundColor = .backgroundColor
    tableView.rowHeight = 105
    tableView.separatorStyle = .singleLine
    tableView.separatorInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 0)

    navigationItem.titleView = UIView(frame: .zero)

    let totalString: String
    let untappedString: String
    switch result {
    case .beers(let beers):
      totalString = "We found \(beers.count) beers"
      untappedString = "."
    case .matches(let untapped, let tapped):
      let total = untapped.count + tapped.count
      totalString = "We found \(total) beers"
      untappedString = untapped.isEmpty ? "." : ", and you haven’t checkd \(untapped.count) of them."
    }

    countLabel.text = "\(totalString)\(untappedString)"
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    switch result {
    case .beers:
      return 1
    case .matches:
      return 2
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

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

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.beerResultCell, for: indexPath) else {
      return UITableViewCell()
    }

    cell.viewModel = BeerResultCell.ViewModel(beer: beer(for: indexPath), uncheckd: indexPath.section == 1)

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let bier = beer(for: indexPath)

    if let schemaUrl = URL(string: "untappd://beer/\(bier.bid ?? 0)"),
      UIApplication.shared.canOpenURL(schemaUrl) {
      UIApplication.shared.open(schemaUrl, options: [:], completionHandler: nil)
    } else {
      UIApplication.shared.open(URL(string: "https://untappd.com/beer/\(bier.bid ?? 0)")!, options: [:], completionHandler: nil)
    }
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

    switch result {
    case .beers:
      return nil
    case .matches(let tappd, let untappd):
      if section == 1 {
        return untappd.isEmpty ? nil : "ALREADY CHECKD"
      } else {
        return tappd.isEmpty ? nil : "UNCHECKD"
      }
    }
  }

}
