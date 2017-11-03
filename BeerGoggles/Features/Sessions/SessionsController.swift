//
//  SessionsController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit

class SessionsController: UITableViewController {

  private let sessions = ["Heineken"]

  init() {
    super.init(style: .plain)

    title = "Previous"
    tabBarItem = UITabBarItem(title: "PREVIOUS", image: R.image.previous(), tag: 1)
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

    cell.textLabel?.text = sessions[indexPath.row]

    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    navigationController?.pushViewController(SessionDetailController(), animated: true)
  }
}
