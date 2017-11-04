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
    case matches(strings: [String], beers: [BeerJson], guid: UUID)
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

    animate()

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
          controllers[1] = result.possibles.isEmpty ?
            BeerResultOverviewController(beers: result.matches.map({ $0.beer })) :
            BeerCaptureOverviewController(result: result, guid: guid)
          navigationController?.setViewControllers(controllers, animated: true)
        }
        .trap {
          print($0)
        }

    case .matches(let strings, let beers, let guid):
      ApiService.shared.magic(matches: strings)
        .mapError()
        .flatMap { (result: [MatchesJson]) -> Promise<[MatchesJson], Error> in
          DatabaseService.shared.add(beers: beers, id: guid)
            .map { result }
        }
        .then { [navigationController] matches in
          var controllers = navigationController?.viewControllers ?? []
          controllers[2] = BeerResultOverviewController(beers: Array([matches.map({ $0.beer }), beers].joined()))
          navigationController?.setViewControllers(controllers, animated: true)
        }
        .trap {
          print($0)
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
}
