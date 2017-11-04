//
//  SessionsController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class SessionsController: UITableViewController {

  private var sessions: [Session] = [] {
    didSet {
      tableView?.reloadData()
    }
  }

  init() {
    super.init(style: .plain)

    title = "SESSIONS"
    tabBarItem = UITabBarItem(title: "SESSIONS", image: R.image.previous(), tag: 1)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.backgroundColor = Colors.backgroundColor
    tableView.rowHeight = 65
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    DatabaseService.shared.sessions().then { [weak self] sessions in
      self?.sessions = sessions
    }.trap {
      print($0)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return sessions.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell") ?? UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "DefaultCell")

    let session = sessions[indexPath.row]
    cell.textLabel?.text = "\(session.captureDate)"
    cell.textLabel?.textColor = .white
    cell.textLabel?.font = Fonts.futuraMedium(with: 18)
    cell.backgroundColor = Colors.backgroundColor

    let fileOptional = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
      .first
      .flatMap { URL(string: $0) }?
      .appendingPathComponent("\(session.imageGuid).jpg")

    if let file = fileOptional {
      let data = FileManager.default.contents(atPath: file.absoluteString)
      cell.imageView?.image = data.flatMap { UIImage(data: $0) }
    }

    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let controller = BeerResultOverviewController(beers: sessions[indexPath.row].beers)
    navigationController?.pushViewController(controller, animated: true)
  }
}
