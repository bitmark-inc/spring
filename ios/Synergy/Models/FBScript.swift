//
//  FBScript.swift
//  Synergy
//
//  Created by thuyentruong on 11/22/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

struct FBScript: Decodable {
    let name: String
    let detection: String
    let actions: [String: String]

    func script(for action: FBAction) -> String? {
        return actions[action.rawValue]
    }
}

enum FBPage: String {
    case login
    case saveDevice = "save_device"
    case newFeed = "new_feed"
    case settings
    case archive
    case reauth
    case accountPicking
}

enum FBAction: String {
    case login
    case isLogInFailed
    case notNow
    case goToSettingsPage
    case goToArchivePage
    case reauth
    case selectRequestTab
    case selectJSONOption
    case selectHighResolutionOption
    case createFile
    case selectDownloadTab
    case isCreatingFile
    case downloadFirstFile
    case pickAnother
}
