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
import AppTrackingTransparency
import Core
import Networking
import Feed
import Search
import Component
import Authen
import Profile
import Setting
import Farming
import SwiftColor
import FirebaseCore
import FirebaseMessaging
import FirebaseDynamicLinks
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import IQKeyboardManagerSwift
import Defaults
import PanModal
import RealmSwift
import SwiftyJSON
import Swifter
import GoogleSignIn
import FBSDKCoreKit
import PopupDialog
import Adjust
import Report

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var feedNavi: UINavigationController?
    var searchNavi: UINavigationController?
    let tabBarController = UITabBarController()
    let gcmMessageIDKey = "gcm.message_id"
    var isOpenDeepLink: Bool = false
    let viewModel = AppDelegateViewModel()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // MARK: - Prepare Engagement
        Defaults[.screenId] = ScreenId.splashScreen.rawValue

        // MARK: - Setup Adjust
        if Defaults[.isAdjustEnable] {
            let environment = (Environment.appEnv == .prod ? ADJEnvironmentProduction : ADJEnvironmentSandbox)
            let adjustConfig = ADJConfig(appToken: Environment.adjustAppToken, environment: environment)
            adjustConfig?.logLevel = ADJLogLevelVerbose
            adjustConfig?.delegate = self
            Adjust.appDidLaunch(adjustConfig)
        }

        // MARK: - Log network api
        self.viewModel.setupLogApi()

        // MARK: - Check device UUID
        self.viewModel.checkDeviceUuid()

        // MARK: - Reset Load Feed
        Defaults[.startLoadFeed] = true

        // MARK: - Get Version and Build Number
        Defaults[.appVersion] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        Defaults[.appBuild] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "000000000000"

        // MARK: - Load Font
        UIFont.loadAllFonts

        // MARK: - Setup Popup Dialog
        self.setupPopupAppearance()

        // MARK: - Setup Keyboard
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false

        // MARK: - Setup Firebase
        let options = FirebaseOptions.init(contentsOfFile: self.viewModel.getFirebaseConfigFile())!
        FirebaseApp.configure(options: options)

        // MARK: - Migrations Realm
        let config = Realm.Configuration(
            schemaVersion: 19,
            migrationBlock: {_, oldSchemaVersion in
                if oldSchemaVersion < 19 {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                Adjust.requestTrackingAuthorization()
            }
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.resetApplication(notification:)), name: .resetApplication, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openEditProfile(notification:)), name: .updateProfileDelegate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openProfile(notification:)), name: .openProfileDelegate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openSearch(notification:)), name: .openSearchDelegate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openFarmingHistory(notification:)), name: .openFarmmingDelegate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openSignIn(notification:)), name: .openSignInDelegate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openFoller(notification:)), name: .openFollerDelegate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openCast(notification:)), name: .openCastDelegate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openComment(notification:)), name: .openCommentDelegate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openQuoteCastList(notification:)), name: .openQuoteCastListDelegate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openVerify(notification:)), name: .openVerifyDelegate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openVerifyMobile(notification:)), name: .openVerifyMobileDelegate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openRegisterEmail(notification:)), name: .openRegisterEmailDelegate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openReport(notification:)), name: .openReportDelegate, object: nil)

        // MARK: - App Center
        if Environment.appEnv == .prod {
            AppCenter.start(withAppSecret: Environment.appCenterKey, services: [
                Analytics.self,
                Crashes.self
            ])
        }

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

    func setupPopupAppearance() {
        // Customize dialog appearance
        let presentView = PopupDialogDefaultView.appearance()
        presentView.titleFont    = UIFont.asset(.bold, fontSize: .body)
        presentView.titleColor   = UIColor.Asset.darkGraphiteBlue
        presentView.messageFont  = UIFont.asset(.regular, fontSize: .overline)
        presentView.messageColor = UIColor.Asset.darkGraphiteBlue

        // Customize default button appearance
        let defaultButton = DefaultButton.appearance()
        defaultButton.titleFont      = UIFont.asset(.bold, fontSize: .overline)
        defaultButton.titleColor     = UIColor.Asset.darkGraphiteBlue

        // Customize cancel button appearance
        let cancelButton = CancelButton.appearance()
        cancelButton.titleFont      = UIFont.asset(.regular, fontSize: .overline)
        cancelButton.titleColor     = UIColor.Asset.gray
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        let handled: Bool = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        } else if let callbackUrl = URL(string: TwitterConstants.callbackUrl) {
            Swifter.handleOpenURL(url, callbackURL: callbackUrl)
        }
        if let view = self.getQueryStringParameter(url: url.absoluteString, param: "view"), view == "verify_mobile", UserManager.shared.isLogin, !self.isOpenDeepLink {
            self.isOpenDeepLink = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.gotoVerifyMobile()
            }
        }
        if Defaults[.isAdjustEnable] {
            Adjust.appWillOpen(url)
        }
        return ApplicationDelegate.shared.application(app, open: url, options: options)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if Defaults[.isAdjustEnable], userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url: URL = userActivity.webpageURL {
            Adjust.appWillOpen(url)
        }
        let handled = DynamicLinks.dynamicLinks()
            .handleUniversalLink(userActivity.webpageURL!) { dynamiclink, _ in
                print(dynamiclink ?? "")
            }
        return handled
    }

    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
}

// MARK: - Adjust
extension AppDelegate: AdjustDelegate {
    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        // MARK: - Log change attribution
    }

    func adjustDeeplinkResponse(_ deeplink: URL?) -> Bool {
        return true
    }
}

extension AppDelegate {
    func applicationDidBecomeActive(_ application: UIApplication) {
        if !UserManager.shared.accessToken.isEmpty {
            let screenId: ScreenId = ScreenId(rawValue: Defaults[.screenId]) ?? .unknown
            EngagementHelper().sendCastcleAnalytic(event: .startSession, screen: screenId)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if !UserManager.shared.accessToken.isEmpty {
            let screenId: ScreenId = ScreenId(rawValue: Defaults[.screenId]) ?? .unknown
            EngagementHelper().sendCastcleAnalytic(event: .endSession, screen: screenId)
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        if !UserManager.shared.accessToken.isEmpty {
            let screenId: ScreenId = ScreenId(rawValue: Defaults[.screenId]) ?? .unknown
            EngagementHelper().sendCastcleAnalytic(event: .endSession, screen: screenId)
        }
    }
}

extension AppDelegate: SplashScreenViewControllerDelegate {
    func didLoadFinish(_ view: SplashScreenViewController) {
        self.setupTabBar()
        self.window!.rootViewController = self.tabBarController
    }
}

// MARK: - Notification
extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        Messaging.messaging().appDidReceiveMessage(userInfo)

        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }

        print(userInfo)
        print("===")
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
        print("===")

        completionHandler(UIBackgroundFetchResult.newData)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if Defaults[.isAdjustEnable] {
            Adjust.setDeviceToken(deviceToken)
        }
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
        print("===")

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
        print("===")
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
            if !UserManager.shared.isLogin {
                self.tabBarController.selectedIndex = 0
                self.signInView()
            } else if !UserManager.shared.isVerified {
                NotificationCenter.default.post(name: .openVerifyDelegate, object: nil, userInfo: nil)
            } else {
                let viewController = PostOpener.open(.post(PostViewModel(postType: .newCast)))
                viewController.modalPresentationStyle = .fullScreen
                self.tabBarController.present(viewController, animated: true, completion: nil)
            }
        }
    }

    private func signInView() {
        let signInNav = UINavigationController(rootViewController: AuthenOpener.open(.signIn))
        signInNav.modalPresentationStyle = .fullScreen
        Utility.currentViewController().present(signInNav, animated: true)
    }
}

extension AppDelegate {
    @objc func resetApplication(notification: NSNotification) {
        self.setupTabBar()
        self.window!.rootViewController = self.tabBarController
    }

    @objc func openEditProfile(notification: NSNotification) {
        Utility.currentViewController().navigationController?.pushViewController(ProfileOpener.open(.updateUserImage), animated: true)
    }

    @objc func openProfile(notification: NSNotification) {
        if let dict = notification.userInfo as NSDictionary? {
            let castcleId: String = dict[JsonKey.castcleId.rawValue] as? String ?? ""
            let displayName: String = dict[JsonKey.displayName.rawValue] as? String ?? ""
            ProfileOpener.openProfileDetail(castcleId, displayName: displayName)
        }
    }

    @objc func openSearch(notification: NSNotification) {
        if let dict = notification.userInfo as NSDictionary? {
            let hastag: String = dict[JsonKey.hashtag.rawValue] as? String ?? ""
            let viewController = SearchOpener.open(.searchResult(SearchResualViewModel(state: .resualt, textSearch: hastag, feedState: .getContent)))
            Utility.currentViewController().navigationController?.pushViewController(viewController, animated: true)
        }
    }

    @objc func openFarmingHistory(notification: NSNotification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Utility.currentViewController().navigationController?.pushViewController(FarmingOpener.open(.contentFarming), animated: true)
        }
    }

    @objc func openSignIn(notification: NSNotification) {
        self.signInView()
    }

    private func gotoVerifyMobile() {
        self.isOpenDeepLink = false
        Utility.currentViewController().navigationController?.pushViewController(SettingOpener.open(.verifyMobile), animated: true)
    }

    @objc func openFoller(notification: NSNotification) {
        if let dict = notification.userInfo as NSDictionary? {
            let profileId: String = dict[JsonKey.profileId.rawValue] as? String ?? ""
            Utility.currentViewController().navigationController?.pushViewController(ProfileOpener.open(.userFollow(UserFollowViewModel(followType: .follower, castcleId: profileId))), animated: true)
        }
    }

    @objc func openCast(notification: NSNotification) {
        if let dict = notification.userInfo as NSDictionary? {
            let contentId: String = dict[JsonKey.contentId.rawValue] as? String ?? ""
            Utility.currentViewController().navigationController?.pushViewController(ComponentOpener.open(.comment(CommentViewModel(contentId: contentId))), animated: true)
        }
    }

    @objc func openComment(notification: NSNotification) {
        if let dict = notification.userInfo as NSDictionary? {
            let contentId: String = dict[JsonKey.contentId.rawValue] as? String ?? ""
            let commentId: String = dict[JsonKey.commentId.rawValue] as? String ?? ""
            Utility.currentViewController().navigationController?.pushViewController(ComponentOpener.open(.commentDetail(CommentDetailViewModel(contentId: contentId, commentId: commentId))), animated: true)
        }
    }

    @objc func openQuoteCastList(notification: NSNotification) {
        if let dict = notification.userInfo as NSDictionary? {
            let contentId: String = dict[JsonKey.contentId.rawValue] as? String ?? ""
            Utility.currentViewController().navigationController?.pushViewController(FeedOpener.open(.quoteCastList(QuoteCastListViewModel(contentId: contentId))), animated: true)
        }
    }

    @objc func openVerify(notification: NSNotification) {
        Utility.currentViewController().navigationController?.pushViewController(AuthenOpener.open(.resendEmail(ResendEmailViewModel(title: "Setting"))), animated: true)
    }

    @objc func openRegisterEmail(notification: NSNotification) {
        Utility.currentViewController().navigationController?.pushViewController(SettingOpener.open(.registerEmail), animated: true)
    }

    @objc func openVerifyMobile(notification: NSNotification) {
        self.gotoVerifyMobile()
    }

    @objc func openReport(notification: NSNotification) {
        if let dict = notification.userInfo as NSDictionary? {
            let castcleId: String = dict[JsonKey.castcleId.rawValue] as? String ?? ""
            let contentId: String = dict[JsonKey.contentId.rawValue] as? String ?? ""
            Utility.currentViewController().navigationController?.pushViewController(ReportOpener.open(.reportSubject(ReportSubjectViewModel(reportType: castcleId.isEmpty ? .content : .user, castcleId: castcleId, contentId: contentId))), animated: true)
        }
    }
}
