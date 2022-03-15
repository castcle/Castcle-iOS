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
//  RemoteConfigValues.swift
//  Castcle-iOS
//
//  Created by Castcle Co., Ltd. on 14/3/2565 BE.
//

import Firebase
import FirebaseRemoteConfig

enum RemoteConfigKey: String {
    case forceVersion
    case ios
    case version
    case url
}

struct ForceVersion: Codable {
    var force_version: ForceVersionConfig = ForceVersionConfig()
}

struct ForceVersionConfig: Codable {
    var ios: VersionConfig = VersionConfig()
    var android: VersionConfig = VersionConfig()
    var meta: MetaConfig = MetaConfig()
}

struct VersionConfig: Codable {
    var version: String = ""
    var url: String = ""
}

struct MetaConfig: Codable {
    var title: MetaLabel = MetaLabel()
    var message: MetaLabel = MetaLabel()
    var button: MetaLabel = MetaLabel()
}

struct MetaLabel: Codable {
    var en: String = ""
    var th: String = ""
}

class RemoteConfigValues {
    static let shared = RemoteConfigValues()
    private var remoteConfig: RemoteConfig!
    
    private let iosData = [
        "version": "9.9.9",
        "url": "https://apps.apple.com/app/castcle-decentralized-social/id1593824529"
    ]
    
    private init() {
        self.loadDefaultValues()
        self.fetchCloudValues()
    }
    
    func loadDefaultValues() {
        self.remoteConfig = RemoteConfig.remoteConfig()
        let appDefaults: [String: NSObject] = [
            "vetsion_ios": "9.9.9" as NSObject
        ]
        self.remoteConfig.setDefaults(appDefaults)
//        self.remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")
        
    }
    
    func activateDebugMode() {
        let settings = RemoteConfigSettings()
        // WARNING: Don't actually do this in production!
        settings.minimumFetchInterval = 0
        self.remoteConfig.configSettings = settings
    }
    
    func fetchCloudValues() {
        print("==========")
        // 1
        self.activateDebugMode()
        
        self.remoteConfig.fetch(withExpirationDuration: 0) { status, error in
            if status == .success {
                print("Config fetched!")
                self.remoteConfig.activate { changed, error in
//                    let value = self.remoteConfig.configValue(forKey: "force_version").stringValue
                    let version = self.remoteConfig.configValue(forKey: "vetsion_ios").stringValue
//                    print(value)
                    print(version)
                    print(changed)
                    print(error)
                }
            } else {
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "No error available.")")
            }

        }
        
        // 2
//        RemoteConfig.remoteConfig().fetch { _, error in
//            if let error = error {
//                print("Uh-oh. Got an error fetching remote values \(error)")
//                // In a real app, you would probably want to call the loading
//                // done callback anyway, and just proceed with the default values.
//                // I won't do that here, so we can call attention
//                // to the fact that Remote Config isn't loading.
//                return
//            }
//
//            // 3
//            RemoteConfig.remoteConfig().activate { _, _ in
//                print("Retrieved values from the cloud!")
//                print("""
//                  Our app's primary color is \
//                  \(RemoteConfig.remoteConfig().configValue(forKey: "ios"))
//                  """)
//            }
//        }
        self.getVersion()
        print("==========")
    }
    
//    func bool(forKey key: RemoteConfigKey) -> Bool {
//        RemoteConfig.remoteConfig()[key.rawValue].boolValue
//    }
//
//    func string(forKey key: RemoteConfigKey) -> String {
//        RemoteConfig.remoteConfig()[key.rawValue].stringValue ?? ""
//    }
//
//    func double(forKey key: RemoteConfigKey) -> Double {
//        RemoteConfig.remoteConfig()[key.rawValue].numberValue.doubleValue
//    }
    
    func getVersion() {
//        let value = self.remoteConfig.configValue(forKey: "force_version").stringValue
        let version = self.remoteConfig.configValue(forKey: "vetsion_ios").stringValue
//        print(value)
        print(version)
    }
}
