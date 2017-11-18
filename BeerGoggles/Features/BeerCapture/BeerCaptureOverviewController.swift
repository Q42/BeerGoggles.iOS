//
//  BeerCaptureOverviewController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import CancellationToken

class BeerCaptureOverviewController: UIViewController {

  private let result: UploadJson
  private let sessionIdentifier: SessionIdentifier
  private var cancellationTokenSource: CancellationTokenSource!

  @IBOutlet weak private var tableView: UITableView!

  init(result: UploadJson, sessionIdentifier: SessionIdentifier) {
    self.result = result
    self.sessionIdentifier = sessionIdentifier
    super.init(nibName: "BeerCaptureOverviewView", bundle: nil)
    title = "BEERS...?"
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .backgroundColor

    tableView.dataSource = self
    tableView.delegate = self
    tableView.backgroundColor = .backgroundColor
    tableView.register(R.nib.beerSelectCell)
    tableView.rowHeight = 70
    tableView.allowsSelection = true
    tableView.allowsMultipleSelection = true
    tableView.separatorStyle = .singleLine
    tableView.separatorInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 0)
  }

  @IBAction func nextPressed(_ sender: Any) {

    let strings = (tableView.indexPathsForSelectedRows ?? []).map {
      self.result.possibles[$0.row]
    }
    let matches = result.matches
    if strings.isEmpty {
      navigationController?.pushViewController(BeerResultCoordinator.controller(for: matches,
                                                                                identifier: sessionIdentifier),
                                               animated: true)
    } else {
      cancellationTokenSource = CancellationTokenSource()
      App.databaseService.add(possibles: strings, identifier: sessionIdentifier)
        .flatMap { [result, sessionIdentifier] in
          App.imageService.magic(strings: strings,
                                 matches: result.matches,
                                 identifier: sessionIdentifier)
        }
        .map { (newMatches, identifier) in
          (Array([matches, newMatches].joined()), identifier)
        }
        .presentLoader(for: self,
                       cancellationTokenSource: cancellationTokenSource,
                       message: .scanning,
                       handler: { (matches, identifier)  in
          BeerResultCoordinator.controller(for: matches, identifier: identifier)
        })
        .attachError(for: self,
                     handler: { [weak self] (controller) in
          controller.navigationController?.popViewController(animated: true)
          self?.nextPressed(sender)
        })
    }
  }
}

extension BeerCaptureOverviewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    return result.possibles.count
  }

  func tableView(_ tableView: UITableView,
                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.beerSelectCell,
                                                   for: indexPath)
      else {
        return UITableViewCell()
      }

    cell.possibility = result.possibles[indexPath.row]

    return cell
  }
}

extension BeerCaptureOverviewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView,
                 didSelectRowAt indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath)
    cell?.isSelected = true
  }

  func tableView(_ tableView: UITableView,
                 didDeselectRowAt indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath)
    cell?.isSelected = false
  }
}
