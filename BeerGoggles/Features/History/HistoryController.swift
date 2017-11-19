//
//  SessionsController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import CancellationToken

class HistoryController: TableViewController {

  private var sessions: [Session] = []
  private var emptySessions: [Session] = []
  private var unfinishedSessions: [Session] = []

  private var cancellationTokenSource: CancellationTokenSource!
  
  init() {
    super.init(style: .plain)

    title = "HISTORY"
    tabBarItem = UITabBarItem(title: "HISTORY", image: R.image.history(), tag: 1)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.backgroundColor = .backgroundColor
    tableView.rowHeight = 70
    tableView.register(R.nib.historyCell)
    tableView.separatorStyle = .singleLine
    tableView.separatorInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 0)

    navigationItem.titleView = UIView(frame: .zero)
    
    let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    tableView.addGestureRecognizer(recognizer)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    reload()
  }
  
  private func reload() {
    App.databaseService.sessions().then { [weak self, tableView] sessions in
      self?.sessions = sessions.filter {
        !$0.beers.isEmpty && $0.done
      }
      
      self?.emptySessions = sessions.filter {
        $0.beers.isEmpty && $0.done
      }
      
      self?.unfinishedSessions = sessions.filter {
        !$0.done
      }
      
      tableView?.reloadData()
      }.trap {
        print($0)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 3
  }

  private func sessions(for section: Int) -> [Session] {
    switch section {
    case 0:
      return sessions
    case 1:
      return emptySessions
    case 2:
      return unfinishedSessions
    default:
      return []
    }
  }
  
  private func session(for indexPath: IndexPath) -> Session {
    return sessions(for: indexPath.section)[indexPath.row]
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return sessions(for: section).count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.historyCell, for: indexPath) else {
      return UITableViewCell()
    }
    
    cell.session = session(for: indexPath)
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    let session = self.session(for: indexPath)
    
    if !session.done {
      retry(session: session)
    } else if session.beers.isEmpty {
      retry(session: session)
    } else {
      let controller = BeerResultOverviewController(result: .beers(beers: session.beers))
      navigationController?.pushViewController(controller, animated: true)
    }
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    
    if sessions(for: section).isEmpty {
      return nil
    }
    
    switch section {
    case 0:
      return "previous scans"
    case 1:
      return "no results"
    case 2:
      return "unfinished"
    default:
      return nil
    }
  }
  
  private func retry(session: Session) {
    print("RETRY SESSION: \(session)")
    cancellationTokenSource = CancellationTokenSource()
    
    App.imageService.retry(session: session, cancellationToken: cancellationTokenSource.token, progressHandler: nil)
      .presentLoader(for: self, cancellationTokenSource: cancellationTokenSource, message: .scanning, handler: { (result, identifier) in
        BeerResultCoordinator.controller(for: result, identifier: identifier)
      }).attachError(for: self, handler: { [weak self, navigationController] (controller) in
        print("ERROR HANDLED")
        navigationController?.popViewController(animated: true)
        self?.retry(session: session)
      })
  }
  
  @objc private func longPress(recognizer: UIGestureRecognizer) {
    if recognizer.state == .recognized {
      retryAll()
    }
  }
  
  private func retryAll() {
    cancellationTokenSource = CancellationTokenSource()
    App.imageService.retryAll(cancellationToken: cancellationTokenSource.token)
      .trap { [cancellationTokenSource] error in
        print(error)
        cancellationTokenSource?.cancel()
      }
      .finally { [weak self] in
        self?.reload()
      }
  }
}
