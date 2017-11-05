//
//  PhotoUploadController.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import Promissum

class LoadingController: UIViewController {

  enum Request {
    case photo(file: URL, guid: UUID)
    case matches(strings: [String], matches: [MatchesJson], guid: UUID)
  }

  private let request: Request

  @IBOutlet weak private var loadingAnimationView: UIImageView!

  init(request: Request) {
    self.request = request
    super.init(nibName: "LoadingView", bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = Colors.backgroundColor
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    animate()
    action()
  }

  private func action() {
    switch request {
    case .photo(let file, let guid):
      ApiService.shared.upload(photo: file)
        .mapError()
        .flatMap { (result: UploadJson) -> Promise<UploadJson, Error> in
          DatabaseService.shared.save(beers: result.matches.map({ $0.beer }), image: guid)
            .map { result }
        }
        .then { [navigationController] (result: UploadJson) in
          print(result)

          var controllers = navigationController?.viewControllers ?? []

          let controller: UIViewController
          if result.possibles.isEmpty {
            if result.matches.isEmpty {
              controller = BeerEmptyController()
            } else {
              let tapped = result.matches.filter { $0.user_rating != nil }.map { $0.beer }
              let untapped = result.matches.filter { $0.user_rating == nil }.map { $0.beer }
              controller = BeerResultOverviewController(result: .matches(untapped: untapped, tapped: tapped))
            }
          } else {
            controller = BeerCaptureOverviewController(result: result, guid: guid)
          }

          controllers[1] = controller

          navigationController?.setViewControllers(controllers, animated: true)
        }
        .trap { [weak self] error in
          self?.present(error: error)
        }

    case .matches(let strings, let matches, let guid):
      ApiService.shared.magic(matches: strings)
        .mapError()
        .flatMap { (result: [MatchesJson]) -> Promise<[MatchesJson], Error> in
          DatabaseService.shared.add(beers: result.map({ $0.beer }), id: guid)
            .map { result }
        }
        .then { [navigationController] newMatches in
          var controllers = navigationController?.viewControllers ?? []

          let result = Array([matches, newMatches].joined())
          let tapped = result.filter { $0.user_rating != nil }.map { $0.beer }
          let untapped = result.filter { $0.user_rating == nil }.map { $0.beer }

          let controller = result.isEmpty ? BeerEmptyController() : BeerResultOverviewController(result: .matches(untapped: untapped, tapped: tapped))
          controllers[2] = controller
          navigationController?.setViewControllers(controllers, animated: true)
        }
        .trap { [weak self] error in
          self?.present(error: error)
        }
    }
  }

  private func animate() {
    let rotation = CABasicAnimation(keyPath: "transform.rotation")
    rotation.toValue = Double.pi * 2
    rotation.duration = 2
    rotation.repeatCount = HUGE
    loadingAnimationView.layer.add(rotation, forKey: "rotationAnimation")
  }

  private func present(error: Error) {
    let controller = ErrorController(error: error) { errorController in
      errorController.navigationController?.popViewController(animated: true)
    }
    navigationController?.pushViewController(controller, animated: true)
  }
}
