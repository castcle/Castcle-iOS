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
import UserNotifications
import Core
import Networking
import Feed
import Search
import Component
import Post
import Authen
import ESTabBarController_swift
import SwiftColor
import Firebase
import FirebaseDynamicLinks
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import IQKeyboardManagerSwift
import Defaults
import PanModal

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var feedNavi: UINavigationController?
    var searchNavi: UINavigationController?
    let tabBarController = ESTabBarController()
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // MARK: - Prepare Engagement
        Defaults[.screenId] = ScreenId.splashScreen.rawValue
        
        // MARK: - Check device UUID
        if Defaults[.deviceUuid].isEmpty {
            Defaults[.deviceUuid] = UUID().uuidString
        }
        
        // MARK: - Reset Load Feed
        Defaults[.startLoadFeed] = true
        
        // MARK: - Get Version and Build Number
        Defaults[.appVersion] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        Defaults[.appBuild] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "000000000000"
        
        // MARK: - Load Font
        UIFont.loadAllFonts
        
        // MARK: - Setup Keyboard
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        
        // MARK: - Setup Firebase
        var filePath:String!
        if Environment.appEnv == .prod {
            filePath = ConfigBundle.mainApp.path(forResource: "GoogleService-Info", ofType: "plist")
        } else if Environment.appEnv == .stg {
            filePath = ConfigBundle.mainApp.path(forResource: "GoogleService-Info-Stgs", ofType: "plist")
        } else {
            filePath = ConfigBundle.mainApp.path(forResource: "GoogleService-Info-Dev", ofType: "plist")
        }
        let options = FirebaseOptions.init(contentsOfFile: filePath)!
        FirebaseApp.configure(options: options)
        
        // MARK: - Setup Notification
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        application.registerForRemoteNotifications()

        
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
                if UserManager.shared.isLogin {
                    let vc = PostOpener.open(.post(PostViewModel(postType: .newCast)))
                    vc.modalPresentationStyle = .fullScreen
                    tabBarController?.present(vc, animated: true, completion: nil)
                } else {
                    Utility.currentViewController().presentPanModal(AuthenOpener.open(.signUpMethod) as! SignUpMethodViewController)
                }
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
    
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        return application(app, open: url,
                           sourceApplication: options[UIApplication.OpenURLOptionsKey
                                                        .sourceApplication] as? String,
                           annotation: "")
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?,
                     annotation: Any) -> Bool {
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
            return true
        }
        return false
    }
}

extension AppDelegate {
    func applicationDidBecomeActive(_ application: UIApplication) {
        if !Defaults[.accessToken].isEmpty {
            TokenHelper().refreshToken()
            let systemVersion = UIDevice.current.systemVersion
            var engagementRequest: EngagementRequest = EngagementRequest()
            engagementRequest.client = "iOS \(systemVersion)"
            engagementRequest.accountId = UserManager.shared.accountId
            engagementRequest.uxSessionId = UserManager.shared.uxSessionId
            engagementRequest.screenId =  Defaults[.screenId]
            engagementRequest.eventType = EventType.startSession.rawValue
            engagementRequest.timestamp = "\(Date.currentTimeStamp)"
            let engagementHelper: EngagementHelper = EngagementHelper(engagementRequest: engagementRequest)
            engagementHelper.sendEngagement()
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        if !Defaults[.accessToken].isEmpty {
            let systemVersion = UIDevice.current.systemVersion
            var engagementRequest: EngagementRequest = EngagementRequest()
            engagementRequest.client = "iOS \(systemVersion)"
            engagementRequest.accountId = UserManager.shared.accountId
            engagementRequest.uxSessionId = UserManager.shared.uxSessionId
            engagementRequest.screenId =  Defaults[.screenId]
            engagementRequest.eventType = EventType.endSession.rawValue
            engagementRequest.timestamp = "\(Date.currentTimeStamp)"
            let engagementHelper: EngagementHelper = EngagementHelper(engagementRequest: engagementRequest)
            engagementHelper.sendEngagement()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        if !Defaults[.accessToken].isEmpty {
            let systemVersion = UIDevice.current.systemVersion
            var engagementRequest: EngagementRequest = EngagementRequest()
            engagementRequest.client = "iOS \(systemVersion)"
            engagementRequest.accountId = UserManager.shared.accountId
            engagementRequest.uxSessionId = UserManager.shared.uxSessionId
            engagementRequest.screenId =  Defaults[.screenId]
            engagementRequest.eventType = EventType.endSession.rawValue
            engagementRequest.timestamp = "\(Date.currentTimeStamp)"
            let engagementHelper: EngagementHelper = EngagementHelper(engagementRequest: engagementRequest)
            engagementHelper.sendEngagement()
        }
    }
}

extension AppDelegate: SplashScreenViewControllerDelegate {
    func didLoadFinish(_ view: SplashScreenViewController) {
        self.setupTabBar()
        self.window!.rootViewController = self.tabBarController
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print(userInfo)
    }
    
    // [START receive_message]
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult)
                        -> Void) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("APNs token retrieved: \(deviceToken)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
                                    -> Void) {
        let userInfo = notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print(userInfo)
        
        completionHandler([[.alert, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        print(userInfo)
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        Defaults[.firebaseToken] = fcmToken ?? ""
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}
