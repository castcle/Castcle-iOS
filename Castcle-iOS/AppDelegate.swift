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
import ESTabBarController
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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // MARK: - Load Font
        UIFont.loadAllFonts
        
        // MARK: - Setup Firebase
        if Environment.appEnv == .prod {
            let filePath = ConfigBundle.mainApp.path(forResource: "GoogleService-Info", ofType: "plist")
            guard let fileopts = FirebaseOptions(contentsOfFile: filePath!) else {
                assert(false, "Couldn't load config file")
                return true
            }
            FirebaseApp.configure(options: fileopts)
        } else if Environment.appEnv == .stg {
            let filePath = ConfigBundle.mainApp.path(forResource: "GoogleService-Info-Stg", ofType: "plist")
            guard let fileopts = FirebaseOptions(contentsOfFile: filePath!) else {
                assert(false, "Couldn't load config file")
                return true
            }
            FirebaseApp.configure(options: fileopts)
        } else {
            let filePath = ConfigBundle.mainApp.path(forResource: "GoogleService-Info-Dev", ofType: "plist")
            guard let fileopts = FirebaseOptions(contentsOfFile: filePath!) else {
                assert(false, "Couldn't load config file")
                return true
            }
            FirebaseApp.configure(options: fileopts)
        }
        
        // MARK: - App Center
        AppCenter.start(withAppSecret: Environment.appCenterKey, services:[
          Analytics.self,
          Crashes.self
        ])
        print()
        
        // MARK: - Setup TabBar
        let tabBarController = ESTabBarController()
        tabBarController.tabBar.backgroundImage = UIColor.Asset.darkGraphiteBlue.toImage()
        tabBarController.shouldHijackHandler = {
            tabbarController, viewController, index in
            if index == 1 {
                return true
            }
            return false
        }
        
        tabBarController.didHijackHandler = {
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
        
        tabBarController.viewControllers = [self.feedNavi, actionViewController, self.searchNavi] as? [UIViewController] ?? []
        
        // MARK: - Setup View
        let frame = UIScreen.main.bounds
        window = UIWindow(frame: frame)
        window!.rootViewController = tabBarController
        window!.makeKeyAndVisible()
        
        return true
    }
}

