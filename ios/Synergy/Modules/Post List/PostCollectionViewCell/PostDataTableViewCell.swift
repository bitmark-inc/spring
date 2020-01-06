//
//  PostCollectionViewCell.swift
//  Synergy
//
//  Created by thuyentruong on 12/3/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import SwiftDate

protocol ClickableDelegate: class {
    func click(_ textView: UITextView, url: URL)
    func playVideo(_ videoKey: String)
    func errorWhenLoadingMedia(error: Error)
}

protocol PostDataTableViewCell where Self: UITableViewCell {
    var clickableDelegate: ClickableDelegate? { get set }

    func bindData(post: Post)
    func makePostInfo(timestamp: Date, friends: [Friend], locationName: String?) -> String
    func makeSeparator() -> UIView
}

extension PostDataTableViewCell {
    func makePostInfo(timestamp: Date, friends: [Friend], locationName: String?) -> String {
        let timestampText = timestamp.toFormat(Constant.TimeFormat.post)

        let friendTags = friends.map { $0.name }.toSentence()
        let friendTagsText = friends.isEmpty ? "" : R.string.phrase.postPostInfoFriendTags(friendTags)

        var locationTagText = ""
        if let locationName = locationName {
            locationTagText = R.string.phrase.postPostInfoLocationTag(locationName)
        }

        return (timestampText + friendTagsText + locationTagText).localizedUppercase
    }

    func makeSeparator() -> UIView {
        let view = UIView()
        view.flex.direction(.column).define { (flex) in
            flex.addItem()
                .backgroundColor(UIColor(hexString: "#828180")!)
                .margin(3, 0, 0, 0)
                .height(1)
            flex.addItem()
                .backgroundColor(UIColor(hexString: "#828180")!)
                .margin(3, 0, 0, 0)
                .height(1)
        }
        return view
    }

}
