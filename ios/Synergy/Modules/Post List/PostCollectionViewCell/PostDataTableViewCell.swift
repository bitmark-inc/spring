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

protocol ClickableTextDelegate: class {
    func click(_ textView: UITextView, url: URL)
}

protocol PostDataTableViewCell where Self: UITableViewCell {
    var clickableTextDelegate: ClickableTextDelegate? { get set }

    func bindData(post: Post)
    func makePostInfo(timestamp: Date, friends: [Friend], locationName: String?) -> Single<NSMutableAttributedString>
}

extension PostDataTableViewCell {
    func makePostInfo(timestamp: Date, friends: [Friend], locationName: String?) -> Single<NSMutableAttributedString> {
        return Single.create { (event) -> Disposable in
            var links: [(text: String, url: String)] = []
            let timestampText = timestamp.toFormat(Constant.TimeFormat.post)

            let friendNames = friends.map { $0.name }
            let friendTags = friendNames.toSentence()
            let friendTagsText = friendTags.isEmpty ? "" : R.string.phrase.postPostInfoFriendTags(friendTags)

            links = friendNames.compactMap({ (text: $0, url: "\(Constant.appName)://\(GroupKey.friend.rawValue)/\($0.urlEncoded)") })

            var locationTagText = ""
            if let locationName = locationName {
                locationTagText = R.string.phrase.postPostInfoLocationTag(locationName)
                links.append((text: locationName, url: "\(Constant.appName)://\(GroupKey.place.rawValue)/\(locationName.urlEncoded)"))
            }

            let postInfo = timestampText + friendTagsText + locationTagText
            let attributedPostInfo = LinkAttributedString.make(
                       string: postInfo,
                       lineHeight: 1.2,
                       attributes: [.font: R.font.atlasGroteskLight(size: Size.ds(17))!],
                       links: links,
                       linkAttributes: [.font: R.font.atlasGroteskBold(size: Size.ds(17))!])

            event(.success(attributedPostInfo))
            return Disposables.create()
        }
    }
}
