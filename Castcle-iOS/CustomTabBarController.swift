//
//  CustomTabBarController.swift
//  Castcle-iOS
//
//  Created by Tanakorn Phoochaliaw on 6/7/2564 BE.
//

import UIKit
import Feed
import Search
import SwiftIcons

class CustomTabBarController:  UITabBarController, UITabBarControllerDelegate {
    
    var actionViewController: ViewController = ViewController()
    var feedNavi: UINavigationController?
    var searchNavi: UINavigationController?
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.delegate = self
        
        let insets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        let iconSize: CGSize = CGSize(width: 32, height: 32)
        
        // MARK: - Feed
        self.feedNavi = UINavigationController(rootViewController: FeedOpener.open(.feed))
        self.feedNavi?.navigationBar.isHidden = true
        self.feedNavi?.tabBarItem = UITabBarItem.init(title: "", image: UIImage.init(icon: .fontAwesomeSolid(.rss), size: iconSize), tag: 0)
        self.feedNavi?.tabBarItem.imageInsets = insets
                
        // MARK: - Search
        self.searchNavi = UINavigationController(rootViewController: SearchOpener.open(.search))
        self.searchNavi?.navigationBar.isHidden = true
        self.searchNavi?.tabBarItem = UITabBarItem.init(title: "", image: UIImage.init(icon: .fontAwesomeSolid(.search), size: iconSize), tag: 0)
        self.searchNavi?.tabBarItem.imageInsets = insets
        
        // MARK: - Action
        self.actionViewController.tabBarItem = UITabBarItem.init(title: "", image: UIImage.init(icon: .fontAwesomeSolid(.plusSquare), size: iconSize), tag: 0)
        self.actionViewController.tabBarItem.imageInsets = insets
            
        
        self.viewControllers = [self.feedNavi, self.actionViewController, self.searchNavi] as? [UIViewController] ?? []
    }
        
    //MARK: UITabbar Delegate
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.isKind(of: ViewController.self) {
            let vc = ViewController()
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true, completion: nil)
            return false
        }
        
        return true
    }
}
