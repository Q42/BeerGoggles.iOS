//
//  SessionsController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class SessionsController: UITableViewController {

  private var sessions: [Session] = []
  private var emptySessions: [Session] = []

  init() {
    super.init(style: .plain)

    title = "SESSIONS"
    tabBarItem = UITabBarItem(title: "SESSIONS", image: R.image.previous(), tag: 1)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.backgroundColor = Colors.backgroundColor
    tableView.rowHeight = 70
    tableView.register(R.nib.sessionCell)
    tableView.separatorStyle = .singleLine
    tableView.separatorInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 0)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    DatabaseService.shared.sessions().then { [weak self, tableView] sessions in
      self?.sessions = sessions.filter {
        !$0.beers.isEmpty
      }
      
      self?.emptySessions = sessions.filter {
        $0.beers.isEmpty
      }
      
      tableView?.reloadData()
    }.trap {
      print($0)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return section == 0 ? sessions.count : emptySessions.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.sessionCell, for: indexPath) else {
      return UITableViewCell()
    }

    let session = indexPath.section == 0 ? sessions[indexPath.row] : emptySessions[indexPath.row]
    cell.session = session
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let controller = BeerResultOverviewController(result: .beers(beers: sessions[indexPath.row].beers))
    navigationController?.pushViewController(controller, animated: true)
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return section == 0 ? "Previous scans" : "No results"
  }
}
