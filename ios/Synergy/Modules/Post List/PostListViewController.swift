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

class PostListViewController: ViewController, BackNavigator {

    // MARK: - Properties
    fileprivate lazy var sectionTitleLabel = makeSectionTitleLabel()
    fileprivate lazy var sectionTagLabel = makeSectionTagLabel()
    fileprivate lazy var timelineLabel = makeTimelineLabel()
    fileprivate lazy var tableView = PostTableView()
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
                self.tableView.dataSource = self
                self.refreshView()

                Observable.changeset(from: realmPosts)
                    .subscribe(onNext: { [weak self] (_, changes) in
                        guard let self = self, let changes = changes else { return }

                        self.refreshView()
                        self.tableView.applyChangeset(changes)
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
            tableView.isHidden = true
            emptyView.flex.marginTop(35)
        } else {
            emptyView.isHidden = true
            emptyView.flex.marginTop(0)
            tableView.isHidden = false
        }

        emptyView.flex.markDirty()
        tableView.flex.markDirty()
    }

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        loadingState.onNext(.hide)

        let blackBackItem = makeBlackBackItem()

        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem().padding(OurTheme.paddingInset)
                    .direction(.column).define { (flex) in
                        flex.addItem(blackBackItem)

                        flex.addItem().direction(.row).marginTop(6).define { (flex) in
                            flex.addItem(sectionTitleLabel).shrink(1)
                            flex.addItem(sectionTagLabel).marginLeft(5).marginTop(-15)
                        }

                        flex.addItem(timelineLabel).marginTop(7)
                }

                flex.addItem(emptyView)
                flex.addItem(tableView).marginBottom(0).grow(1)
            }
    }

    fileprivate func makeEmptyView() -> Label {
        let label = Label()
        label.isDescription = true
        label.applyBlack(text: R.string.phrase.postsEmpty(), font: R.font.atlasGroteskLight(size: Size.ds(32)))
        label.isHidden = true
        return label
    }
}

extension PostListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts![indexPath.row]
        let cell: PostDataTableViewCell!
        switch post.type {
        case Constant.PostType.update:
            cell = tableView.dequeueReusableCell(withClass: UpdatePostTableViewCell.self, for: indexPath)

        case Constant.PostType.link:
            let linkTableCell = (post.post?.isEmpty ?? true) ? LinkPostTableViewCell.self : LinkCaptionPostTableViewCell.self
            cell = tableView.dequeueReusableCell(withClass: linkTableCell, for: indexPath) as? PostDataTableViewCell

        case Constant.PostType.video:
            cell = tableView.dequeueReusableCell(withClass: VideoPostTableViewCell.self, for: indexPath)

        default:
            cell = tableView.dequeueReusableCell(withClass: GeneralPostTableViewCell.self, for: indexPath)
        }
        cell.clickableTextDelegate = self
        cell.bindData(post: post)
        return cell
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
            gotoPostListScreen(filterBy: filterBy, filterValue: filterValue)
        } else {
            let safariVC = SFSafariViewController(url: url)
            self.present(safariVC, animated: true, completion: nil)
        }
    }
}

// MARK: - Navigator
extension PostListViewController {
    func gotoPostListScreen(filterBy: GroupKey, filterValue: String) {
        guard let viewModel = viewModel as? PostListViewModel else { return }
        loadingState.onNext(.loading)
        let filterScope: FilterScope = (
            usageScope: viewModel.filterScope.usageScope,
            filterBy: filterBy,
            filterValue: filterValue
        )

        let postListviewModel = PostListViewModel(filterScope: filterScope)
        navigator.show(segue: .postList(viewModel: postListviewModel), sender: self)
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
