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

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var feedNavi: UINavigationController?
    var searchNavi: UINavigationController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // MARK: - Load Font
        UIFont.loadAllFonts
        
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
                let alertController = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
                let takePhotoAction = UIAlertAction(title: "Take a photo", style: .default, handler: nil)
                alertController.addAction(takePhotoAction)
                let selectFromAlbumAction = UIAlertAction(title: "Select from album", style: .default, handler: nil)
                alertController.addAction(selectFromAlbumAction)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                tabBarController?.present(alertController, animated: true, completion: nil)
            }
        }
        
        // MARK: - Feed
        self.feedNavi = UINavigationController(rootViewController: FeedOpener.open(.feed))
        self.feedNavi?.navigationBar.isHidden = true
                
        // MARK: - Search
        self.searchNavi = UINavigationController(rootViewController: SearchOpener.open(.search))
        self.searchNavi?.navigationBar.isHidden = true
        
        // MARK: - Action
        let actionViewController: UIViewController = UIViewController()

        self.feedNavi?.tabBarItem = ESTabBarItem.init(BouncesContentView(), image: UIImage.init(icon: .castcle(.alignCenter), size: CGSize(width: 23, height: 23)), selectedImage: UIImage.init(icon: .castcle(.alignCenter), size: CGSize(width: 23, height: 23)))
        actionViewController.tabBarItem = ESTabBarItem.init(IrregularityContentView(), image: UIImage.init(icon: .castcle(.alignJustify), size: CGSize(width: 50, height: 50)), selectedImage: UIImage.init(icon: .castcle(.alignJustify), size: CGSize(width: 50, height: 50)))
        self.searchNavi?.tabBarItem = ESTabBarItem.init(BouncesContentView(), image: UIImage.init(icon: .castcle(.batteryFull), size: CGSize(width: 23, height: 23)), selectedImage: UIImage.init(icon: .castcle(.batteryFull), size: CGSize(width: 23, height: 23)))
        
        tabBarController.viewControllers = [self.feedNavi, actionViewController, self.searchNavi] as? [UIViewController] ?? []
        
        // MARK: - Setup View
        let frame = UIScreen.main.bounds
        window = UIWindow(frame: frame)
        window!.rootViewController = tabBarController
        window!.makeKeyAndVisible()
        
        return true
    }
}

