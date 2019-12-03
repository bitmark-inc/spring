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

protocol ClickableTextDelegate {
    func click(_ textView: UITextView, url: URL)
}

protocol PostDataCollectionViewCell where Self: UICollectionViewCell {
    func bindData(post: Post)
    func makePostInfo(of post: Post) -> NSMutableAttributedString
}

extension PostDataCollectionViewCell {
    func makePostInfo(of post: Post) -> NSMutableAttributedString {
        var links: [(text: String, url: String)] = []
        let timestampText = post.timestamp.toFormat(Constant.postTimestampFormat)

        let friendTags = post.tags.toSentence()
        let friendTagsText = friendTags.isEmpty ? "" : R.string.phrase.postPostInfoFriendTags(friendTags)

        links = post.tags.compactMap({ (text: $0, url: "\(Constant.appName)://\(GroupKey.friend.rawValue)/\($0.urlEncoded)") })

        let location = post.location
        var locationTagText = ""
        if !location.isEmpty {
            locationTagText = R.string.phrase.postPostInfoLocationTag(post.location)
            links.append((text: location, url: "\(Constant.appName)://\(GroupKey.place.rawValue)/\(location.urlEncoded)"))
        }

        let postInfo = timestampText + friendTagsText + locationTagText
        return LinkAttributedString.make(
                   string: postInfo,
                   lineHeight: 1.2,
                   attributes: [.font: R.font.atlasGroteskThin(size: Size.ds(17))!],
                   links: links,
                   linkAttributes: [.font: R.font.atlasGroteskBold(size: Size.ds(17))!])
    }
}
