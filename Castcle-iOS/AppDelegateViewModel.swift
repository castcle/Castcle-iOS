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
//  AppDelegateViewModel.swift
//  Castcle-iOS
//
//  Created by Castcle Co., Ltd. on 21/10/2564 BE.
//

import Core
import netfox
import Defaults

class AppDelegateViewModel {
    func setupLogApi() {
        if Environment.appEnv != .prod {
            NFX.sharedInstance().ignoreURLs(LogUrl.ignoreURLs)
            NFX.sharedInstance().start()
        }
    }

    func checkDeviceUuid() {
        let castcleDeviceId: String = KeychainHelper.shared.getKeychainWith(with: .castcleDeviceId)
        if castcleDeviceId.isEmpty {
            if Defaults[.deviceUuid].isEmpty {
                let deviceUdid = UUID().uuidString
                Defaults[.deviceUuid] = deviceUdid
                KeychainHelper.shared.setKeychainWith(with: .castcleDeviceId, value: deviceUdid)
            } else {
                KeychainHelper.shared.setKeychainWith(with: .castcleDeviceId, value: Defaults[.deviceUuid])
            }
        } else {
            Defaults[.deviceUuid] = castcleDeviceId
        }
    }

    func getFirebaseConfigFile() -> String {
        if Environment.appEnv == .prod {
            return ConfigBundle.mainApp.path(forResource: "GoogleService-Info", ofType: "plist") ?? ""
        } else if Environment.appEnv == .stg {
            return ConfigBundle.mainApp.path(forResource: "GoogleService-Info-Stg", ofType: "plist") ?? ""
        } else {
            return ConfigBundle.mainApp.path(forResource: "GoogleService-Info-Dev", ofType: "plist") ?? ""
        }
    }
}
