//  Copyright (c) 2021, Castcle and/or its affiliates. All rights reserved.
//  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
//
//  This code is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 only, as
//  published by the Free Software Foundation.
//
//  This code is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
//  version 3 for more details (a copy is included in the LICENSE file that
//  accompanied this code).
//
//  You should have received a copy of the GNU General Public License version
//  3 along with this work; if not, write to the Free Software Foundation,
//  Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
//
//  Please contact Castcle, 22 Phet Kasem 47/2 Alley, Bang Khae, Bangkok,
//  Thailand 10160, or visit www.castcle.com if you need additional information
//  or have any questions.
//
//  AppDelegate.swift
//  Castcle-iOS
//
//  Created by Tanakorn Phoochaliaw on 2/7/2564 BE.
//

import UIKit
import Core
import Feed
import Search
import Component
import ESTabBarController_swift
import SwiftColor
import Firebase
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var feedNavi: UINavigationController?
    var searchNavi: UINavigationController?
    let tabBarController = ESTabBarController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // MARK: - Load Font
        UIFont.loadAllFonts
        
        // MARK: - Setup Firebase
        var filePath:String!
        if Environment.appEnv == .prod {
            filePath = ConfigBundle.mainApp.path(forResource: "GoogleService-Info", ofType: "plist")
        } else if Environment.appEnv == .stg {
            filePath = ConfigBundle.mainApp.path(forResource: "GoogleService-Info-Stg", ofType: "plist")
        } else {
            filePath = ConfigBundle.mainApp.path(forResource: "GoogleService-Info-Dev", ofType: "plist")
        }
        let options = FirebaseOptions.init(contentsOfFile: filePath)!
        FirebaseApp.configure(options: options)
        
        // MARK: - App Center
        AppCenter.start(withAppSecret: Environment.appCenterKey, services:[
            Analytics.self,
            Crashes.self
        ])
        
        // MARK: - Setup Splash Screen
        let splashScreenViewController = ComponentOpener.open(.splashScreen) as? SplashScreenViewController
        splashScreenViewController?.delegate = self
        
        // MARK: - Setup View
        let frame = UIScreen.main.bounds
        self.window = UIWindow(frame: frame)
        self.window!.rootViewController = splashScreenViewController
        self.window!.overrideUserInterfaceStyle = .dark
        self.window!.makeKeyAndVisible()
        
        return true
    }
    
    func setupTabBar() {
        // MARK: - Setup TabBar
        self.tabBarController.tabBar.backgroundImage = UIColor.Asset.darkGraphiteBlue.toImage()
        self.tabBarController.shouldHijackHandler = {
            tabbarController, viewController, index in
            if index == 1 {
                return true
            }
            return false
        }
        
        self.tabBarController.didHijackHandler = {
            [weak tabBarController] tabbarController, viewController, index in
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let alert = UIAlertController(title: nil, message: "Go to post view", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                tabBarController?.present(alert, animated: true, completion: nil)
            }
        }
        
        // MARK: - Feed
        self.feedNavi = UINavigationController(rootViewController: FeedOpener.open(.feed))
                
        // MARK: - Search
        self.searchNavi = UINavigationController(rootViewController: SearchOpener.open(.search))
        
        // MARK: - Action
        let actionViewController: UIViewController = UIViewController()

        self.feedNavi?.tabBarItem = ESTabBarItem.init(BouncesContentView(), image: UIImage.init(icon: .castcle(.feed), size: CGSize(width: 23, height: 23)), selectedImage: UIImage.init(icon: .castcle(.feed), size: CGSize(width: 23, height: 23)))
        actionViewController.tabBarItem = ESTabBarItem.init(IrregularityContentView(), image: UIImage(named: "add-content"), selectedImage: UIImage(named: "add-content"))
        self.searchNavi?.tabBarItem = ESTabBarItem.init(BouncesContentView(), image: UIImage.init(icon: .castcle(.search), size: CGSize(width: 23, height: 23)), selectedImage: UIImage.init(icon: .castcle(.search), size: CGSize(width: 23, height: 23)))
        
        self.tabBarController.viewControllers = [self.feedNavi, actionViewController, self.searchNavi] as? [UIViewController] ?? []
    }
}

extension AppDelegate: SplashScreenViewControllerDelegate {
    func didLoadFinish(_ view: SplashScreenViewController) {
        self.setupTabBar()
        self.window!.rootViewController = self.tabBarController
    }
}
