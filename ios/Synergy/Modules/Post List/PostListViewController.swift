//
//  PostListViewController.swift
//  Synergy
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import RxCocoa
import SwiftDate
import RealmSwift
import RxRealm
import SafariServices

class PostListViewController: TabPageViewController {

    // MARK: - Properties
    fileprivate lazy var sectionTitleLabel = makeSectionTitleLabel()
    fileprivate lazy var sectionTagLabel = makeSectionTagLabel()
    fileprivate lazy var timelineLabel = makeTimelineLabel()
    fileprivate lazy var collectionView = PostsCollectionView()
    fileprivate lazy var emptyView = makeEmptyView()

    var posts: Results<Post>?
    lazy var thisViewModel = viewModel as? PostListViewModel

    // MARK: - bind ViewModel
    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? PostListViewModel else { return }

        let sectionInfo = viewModel.generateSectionInfoText()
        sectionTitleLabel.setText(sectionInfo.sectionTitle)
        sectionTagLabel.setText(sectionInfo.taggedText)
        timelineLabel.setText(sectionInfo.timelineText)

        viewModel.postsObservable
            .subscribe(onNext: { [weak self] (realmPosts) in
                guard let self = self else { return }
                self.posts = realmPosts
                self.collectionView.dataSource = self
                self.refreshView()

                Observable.changeset(from: realmPosts)
                    .subscribe(onNext: { [weak self] (_, changes) in
                        guard let self = self, let changes = changes else { return }

                        self.refreshView()
                        self.collectionView.applyChangeset(changes)
                    }, onError: { (error) in
                        Global.log.error(error)
                    })
                    .disposed(by: self.disposeBag)

            })
            .disposed(by: disposeBag)

        viewModel.getPosts()
    }

    func refreshView() {
        if posts?.isEmpty ?? true {
            emptyView.isHidden = false
            collectionView.isHidden = true
            emptyView.flex.marginTop(35)
        } else {
            emptyView.isHidden = true
            emptyView.flex.marginTop(0)
            collectionView.isHidden = false
        }
    }

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        loadingState.onNext(.hide)

        collectionView.delegate = self

        titleView.flex.addItem().direction(.row).define { (flex) in
            flex.addItem(sectionTitleLabel).marginTop(15).shrink(1)
            flex.addItem(sectionTagLabel).marginLeft(5)
        }

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem(timelineLabel).marginTop(15).marginLeft(17)

            flex.addItem(emptyView)
            flex.addItem(collectionView).marginBottom(0).grow(1)
        }

        contentView.flex.layout(mode: .adjustHeight)
    }

    fileprivate func makeEmptyView() -> Label {
        let label = Label()
        label.isDescription = true
        label.applyBlack(text: R.string.phrase.postsEmpty(), font: R.font.atlasGroteskLight(size: Size.ds(32)))
        label.isHidden = true
        return label
    }
}

extension PostListViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let post = posts![indexPath.row]
        let cell: PostDataCollectionViewCell!
        switch post.type {
        case Constant.PostType.update:
            cell = collectionView.dequeueReusableCell(withClass: UpdatePostCollectionViewCell.self, for: indexPath)

        case Constant.PostType.link:
            let linkCollectionCell = (post.post?.isEmpty ?? true) ? LinkPostCollectionViewCell.self : LinkCaptionPostCollectionViewCell.self
            cell = collectionView.dequeueReusableCell(withClass: linkCollectionCell, for: indexPath) as? PostDataCollectionViewCell

        case Constant.PostType.video:
            cell = collectionView.dequeueReusableCell(withClass: VideoPostCollectionViewCell.self, for: indexPath)

        default:
            cell = collectionView.dequeueReusableCell(withClass: GeneralPostCollectionViewCell.self, for: indexPath)
        }
        cell.clickableTextDelegate = self
        cell.bindData(post: post)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
      return Size.dw(18)
    }
}

extension PostListViewController: ClickableTextDelegate {
    func click(_ textView: UITextView, url: URL) {
        if url.scheme == Constant.appName {
            guard let host = url.host,
                let filterBy = GroupKey(rawValue: host)
                else {
                    return
            }

            let filterValue = url.lastPathComponent
            thisViewModel?.gotoPostList(filterBy: filterBy, filterValue: filterValue)
        } else {
            let safariVC = SFSafariViewController(url: url)
            self.present(safariVC, animated: true, completion: nil)
        }
    }
}

extension PostListViewController {
    func makeTimelineLabel() -> Label {
        let label = Label()
        label.applyBlack(
            text: "",
            font: R.font.atlasGroteskLight(size: Size.ds(14)),
            lineHeight: 1.06)
        return label
    }

    func makeSectionTitleLabel() -> Label {
        let label = Label()
        label.applyBlack(
            text: "",
            font: R.font.domaineSansTextRegular(size: Size.ds(36)),
            lineHeight: 1.06, level: 3)
        return label
    }

    func makeSectionTagLabel() -> Label {
        let label = Label()
        label.applyBlack(
            text: "",
            font: R.font.atlasGroteskLight(size: Size.ds(10)),
            lineHeight: 1.06)
        return label
    }
}
