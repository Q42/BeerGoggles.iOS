//
//  AppDelegate.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 03-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import UIKit
import CoreData
import SafariServices
import AVKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  static var instance: AppDelegate {
    return UIApplication.shared.delegate as! AppDelegate
  }

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

    Fabric.with([Crashlytics.self])
    App.authenticationService.migrate()
    applyAppearance()

    window = UIWindow(frame: UIScreen.main.bounds)
    backToRoot()
    window?.makeKeyAndVisible()

    return true
  }

  func backToRoot() {

    let controller: UIViewController
    if !App.authenticationService.isLoggedIn() {
      controller = LoginController()
    } else {
      controller = TabController()
    }

    window?.rootViewController = controller
  }

  private func applyAppearance() {
    UINavigationBar.appearance().tintColor = .barTextColor
    UINavigationBar.appearance().barTintColor = .clear
    UINavigationBar.appearance().shadowImage = UIImage()
    UINavigationBar.appearance().isTranslucent = true
    UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
    UINavigationBar.appearance().backIndicatorImage = R.image.back()
    UINavigationBar.appearance().backIndicatorTransitionMaskImage = R.image.back()

    UIBarButtonItem.appearance().setTitleTextAttributes([
      .font: Fonts.futuraBold(with: 16)
    ], for: .normal)

    UINavigationBar.appearance().titleTextAttributes = [
      .foregroundColor: UIColor.textColor,
      .font: Fonts.futuraBold(with: 20)
    ]

    UITabBar.appearance().barTintColor = .tintColor
    UITabBar.appearance().tintColor = .white
    UITabBar.appearance().unselectedItemTintColor = .backgroundColor
    UITabBarItem.appearance().setTitleTextAttributes([
      .font: Fonts.futuraBold(with: 10)
    ], for: .normal)
  }

  func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
    App.apiService.handleFinishBackground(completionHandler: completionHandler)
  }

  // MARK: - Handle URL

  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    switch url.host {
    case "login"?:
      handleLogin(url: url)
      return true
    default:
      return false
    }
  }

  private func handleLogin(url: URL) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
      let accessToken = components.queryItems?.first(where: { item -> Bool in item.name == "access_token" })?.value
      else {
        return
      }

    App.authenticationService.login(with: AuthenticationToken(rawValue: accessToken))
    
    guard let safariViewController = topMostViewController() as? SFSafariViewController else {
      return
    }

    safariViewController.dismiss(animated: true, completion: nil)
    AppDelegate.instance.backToRoot()
  }

  func topMostViewController() -> UIViewController? {
    guard let root = window?.rootViewController else {
      return nil
    }

    var topViewController = root.presentedViewController
    while (topViewController?.presentedViewController != nil) {
      topViewController = topViewController?.presentedViewController
    }

    return topViewController
  }

}

extension UINavigationController {

  open override var childViewControllerForStatusBarHidden: UIViewController? {
    return topViewController
  }

  open override var childViewControllerForStatusBarStyle: UIViewController? {
    return topViewController
  }

}
