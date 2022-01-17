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
//  Created by Castcle Co., Ltd. on 2/7/2564 BE.
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
import Profile
import SwiftColor
import Firebase
import FirebaseDynamicLinks
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import IQKeyboardManagerSwift
import Defaults
import PanModal
import RealmSwift
import SwiftKeychainWrapper
import SwiftyJSON
import Swifter
import GoogleSignIn
import FBSDKCoreKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var feedNavi: UINavigationController?
    var searchNavi: UINavigationController?
    let tabBarController = UITabBarController()
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // MARK: - Prepare Engagement
        Defaults[.screenId] = ScreenId.splashScreen.rawValue
        
        // MARK: - Check device UUID
        if let castcleDeviceId: String = KeychainWrapper.standard.string(forKey: "castcleDeviceId") {
            Defaults[.deviceUuid] = castcleDeviceId
        } else {
            if Defaults[.deviceUuid].isEmpty {
                let deviceUdid = UUID().uuidString
                Defaults[.deviceUuid] = deviceUdid
                let _: Bool = KeychainWrapper.standard.set(deviceUdid, forKey: "castcleDeviceId")
            } else {
                let _: Bool = KeychainWrapper.standard.set(Defaults[.deviceUuid], forKey: "castcleDeviceId")
            }
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
            filePath = ConfigBundle.core.path(forResource: "GoogleService-Info", ofType: "plist")
        } else if Environment.appEnv == .stg {
            filePath = ConfigBundle.core.path(forResource: "GoogleService-Info-Stg", ofType: "plist")
        } else {
            filePath = ConfigBundle.core.path(forResource: "GoogleService-Info-Dev", ofType: "plist")
        }
        let options = FirebaseOptions.init(contentsOfFile: filePath)!
        FirebaseApp.configure(options: options)
        
        // MARK: - Migrations Realm
        let config = Realm.Configuration(
            schemaVersion: 8,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 8) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
            })
        Realm.Configuration.defaultConfiguration = config
        
        // MARK: - Setup Notification
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (success, error) in
            if error == nil {
                if success {
                    DispatchQueue.main.async {
                      UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    print("Permission denied")
                }
            } else {
                print(error as Any)
            }
        }
        
        // MARK: - Setup Notification Center
        NotificationCenter.default.addObserver(self, selector: #selector(self.openEditProfile(notification:)), name: .updateProfileDelegate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openProfile(notification:)), name: .openProfileDelegate, object: nil)
        
        // MARK: - App Center
        AppCenter.start(withAppSecret: Environment.appCenterKey, services:[
            Analytics.self,
            Crashes.self
        ])
        
        // MARK: - Facebook Login
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
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
        UITabBar.appearance().barTintColor = UIColor.Asset.darkGraphiteBlue
        UITabBar.appearance().isTranslucent = false
        self.tabBarController.tabBar.tintColor = UIColor.Asset.lightBlue
        self.tabBarController.tabBar.unselectedItemTintColor = UIColor.Asset.white
        self.tabBarController.delegate = self
        
        let bottomSafeAreaHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0.0
        let inset: CGFloat = (bottomSafeAreaHeight > 20 ? 10.0 : 5.0)
        let insets = UIEdgeInsets(top: inset, left: 0, bottom: -inset, right: 0)
        
        // MARK: - Feed
        self.feedNavi = UINavigationController(rootViewController: FeedOpener.open(.feed))
        let iconFeed = UITabBarItem(title: nil, image: UIImage.init(icon: .castcle(.feed), size: CGSize(width: 23, height: 23)), selectedImage: UIImage.init(icon: .castcle(.feed), size: CGSize(width: 23, height: 23)))
        self.feedNavi?.tabBarItem = iconFeed
        self.searchNavi?.tabBarItem.tag = 0
        self.feedNavi?.tabBarItem.imageInsets = insets
                
        // MARK: - Search
        self.searchNavi = UINavigationController(rootViewController: SearchOpener.open(.search))
        let iconSearch = UITabBarItem(title: nil, image: UIImage.init(icon: .castcle(.search), size: CGSize(width: 23, height: 23)), selectedImage: UIImage.init(icon: .castcle(.search), size: CGSize(width: 23, height: 23)))
        self.searchNavi?.tabBarItem = iconSearch
        self.searchNavi?.tabBarItem.tag = 2
        self.searchNavi?.tabBarItem.imageInsets = insets
        
        // MARK: - Action
        let actionViewController: UIViewController = UIViewController()
        actionViewController.tabBarItem.image = UIImage(named: "add-content")?.withRenderingMode(.alwaysOriginal)
        actionViewController.tabBarItem.tag = 1
        actionViewController.tabBarItem.imageInsets = insets
        
        self.tabBarController.viewControllers = [self.feedNavi!, actionViewController, self.searchNavi!]
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        let handled: Bool = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        } else if let callbackUrl = URL(string: TwitterConstants.callbackUrl) {
            Swifter.handleOpenURL(url, callbackURL: callbackUrl)
        }
        return ApplicationDelegate.shared.application(app, open: url, options: options)
    }
}

extension AppDelegate {
    func applicationDidBecomeActive(_ application: UIApplication) {
        if !Defaults[.accessToken].isEmpty {
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

extension AppDelegate: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.tabBarItem.tag == 1 {
            self.createPost()
            return false
        }
        
        if viewController.tabBarItem.tag == 0 {
            NotificationCenter.default.post(name: .feedScrollToTop, object: nil)
        }
        
        return true
    }
    
    private func createPost() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if UserManager.shared.isLogin {
                let vc = PostOpener.open(.post(PostViewModel(postType: .newCast)))
                vc.modalPresentationStyle = .fullScreen
                self.tabBarController.present(vc, animated: true, completion: nil)
            } else {
                self.tabBarController.selectedIndex = 0
                Utility.currentViewController().presentPanModal(AuthenOpener.open(.signUpMethod) as! SignUpMethodViewController)
            }
        }
    }
}

extension AppDelegate {
    @objc func openEditProfile(notification: NSNotification) {
        Utility.currentViewController().navigationController?.pushViewController(ProfileOpener.open(.welcome), animated: true)
    }
    
    @objc func openProfile(notification: NSNotification) {
        if let dict = notification.userInfo as NSDictionary? {
            let id: String = dict[AuthorKey.id.rawValue] as? String ?? ""
            let type: AuthorType = AuthorType(rawValue: dict[AuthorKey.type.rawValue] as? String ?? "") ?? .people
            let castcleId: String = dict[AuthorKey.castcleId.rawValue] as? String ?? ""
            let displayName: String = dict[AuthorKey.displayName.rawValue] as? String ?? ""
            let avatar: String = dict[AuthorKey.avatar.rawValue] as? String ?? ""
            if type == .page {
                ProfileOpener.openProfileDetail(type, castcleId: nil, displayName: "", page: Page().initCustom(id: id, displayName: displayName, castcleId: castcleId, avatar:avatar, cover: ""))
            } else {
                ProfileOpener.openProfileDetail(type, castcleId: castcleId, displayName: displayName, page: nil)
            }
        }
    }
}
