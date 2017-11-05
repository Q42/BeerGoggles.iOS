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

    applyAppearance()

    window = UIWindow(frame: UIScreen.main.bounds)
    backToRoot()
    window?.makeKeyAndVisible()

    return true
  }

  func backToRoot() {

    let controller: UIViewController
    if !ApiService.shared.isLoggedIn() {
      controller = LoginController()
    } else if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
      controller = AuthorizationController()
    } else {
      controller = TabController()
    }

    window?.rootViewController = controller
  }

  private func applyAppearance() {
    UINavigationBar.appearance().tintColor = Colors.textColor
    UINavigationBar.appearance().barTintColor = Colors.tintColor
    UINavigationBar.appearance().shadowImage = UIImage()
    UINavigationBar.appearance().titleTextAttributes = [
      .foregroundColor: Colors.textColor,
      .font: Fonts.futuraBold(with: 20)
    ]

    UITabBar.appearance().barTintColor = Colors.backgroundColor
    UITabBar.appearance().tintColor = Colors.tintColor
    UITabBarItem.appearance().setTitleTextAttributes([
      .font: Fonts.futuraMedium(with: 8)
    ], for: .normal)
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
//    self.saveContext()
  }

//  func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
//    <#code#>
//  }

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

    ApiService.shared.login(with: accessToken)
    guard let safariViewController = topMostViewController() as? SFSafariViewController else {
      return
    }

    safariViewController.dismiss(animated: true, completion: nil)
    AppDelegate.instance.backToRoot()
  }

  private func topMostViewController() -> UIViewController? {
    guard let root = window?.rootViewController else {
      return nil
    }

    var topViewController = root.presentedViewController
    while (topViewController?.presentedViewController != nil) {
      topViewController = topViewController?.presentedViewController
    }

    return topViewController
  }

  // MARK: - Core Data Saving support

//  func saveContext () {
//      let context = persistentContainer.viewContext
//      if context.hasChanges {
//          do {
//              try context.save()
//          } catch {
//              // Replace this implementation with code to handle the error appropriately.
//              // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//              let nserror = error as NSError
//              fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//          }
//      }
//  }

}

