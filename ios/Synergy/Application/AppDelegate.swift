//
//  AppDelegate.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import Intercom
import SVProgressHUD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.makeKeyAndVisible()
    
    // SVProgressHUD
    SVProgressHUD.setContainerView(window)
    SVProgressHUD.setMinimumDismissTimeInterval(0.5)
    SVProgressHUD.setDefaultMaskType(.black)
    SVProgressHUD.setHapticsEnabled(true)
    
    // setup Intercom
    Intercom.setApiKey(Constant.default.intercomAppKey, forAppId: Constant.default.intercomAppID)
    
    // IQKeyboardManager
    IQKeyboardManager.shared.enable = true
    IQKeyboardManager.shared.shouldResignOnTouchOutside = true
    IQKeyboardManager.shared.enableAutoToolbar = false
    
    if #available(iOS 13, *) {
      // already execute app flow in SceneDelegate
    } else {
      Application.shared.presentInitialScreen(in: window!)
    }
    
    // Override point for customization after application launch.
    return true
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }


}

