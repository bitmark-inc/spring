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
    fileprivate lazy var tableView = PostTableView()
    fileprivate lazy var emptyView = makeEmptyView()
    fileprivate lazy var backItem = makeBlackBackItem()

    var posts: Results<Post>?
    lazy var thisViewModel = viewModel as! PostListViewModel

    // MARK: - bind ViewModel
    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? PostListViewModel else { return }

        viewModel.postsObservable
            .subscribe(onNext: { [weak self] (realmPosts) in
                guard let self = self else { return }
                self.posts = realmPosts
                self.tableView.reloadData()
                self.refreshView()

                Observable.changeset(from: realmPosts)
                    .subscribe(onNext: { [weak self] (_, changes) in
                        guard let self = self, let changes = changes else { return }

                        self.refreshView()
                        self.tableView.applyChangeset(changes, section: 1)
                    }, onError: { (error) in
                        Global.log.error(error)
                    })
                    .disposed(by: self.disposeBag)

            })
            .disposed(by: disposeBag)

        viewModel.getPosts()
    }

    func refreshView() {
        let hasPosts = posts != nil && !posts!.isEmpty
        emptyView.isHidden = hasPosts
        tableView.isScrollEnabled = hasPosts
    }

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        loadingState.onNext(.hide)

        tableView.dataSource = self

        contentView.flex
            .direction(.column).alignContent(.center).define { (flex) in
                flex.addItem(tableView).grow(1)
                flex.addItem(emptyView)
                    .position(.absolute)
                    .top(200).left(OurTheme.paddingInset.left)
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
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return posts?.count ?? 0
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withClass: ListHeadingViewCell.self, for: indexPath)
            cell.fillInfo(
                backButton: backItem,
                sectionInfo: (
                    sectionTitle: thisViewModel.makeSectionTitle(),
                    taggedText: thisViewModel.makeTaggedText(),
                    timelineText: thisViewModel.makeTimelineText()))

            return cell

        case 1:
            let post = posts![indexPath.row]
            guard let postType = PostType(rawValue: post.type) else {
                return UITableViewCell()
            }

            let cell: PostDataTableViewCell!
            switch postType {
            case .update:
                cell = tableView.dequeueReusableCell(withClass: UpdatePostTableViewCell.self, for: indexPath)

            case .link:
                cell = tableView.dequeueReusableCell(withClass: LinkPostTableViewCell.self, for: indexPath)

            case .media:
                cell = post.mediaData.first?.type == "video" ?
                    tableView.dequeueReusableCell(withClass: VideoPostTableViewCell.self, for: indexPath) :
                    tableView.dequeueReusableCell(withClass: PhotoPostTableViewCell.self, for: indexPath)

            default:
                cell = tableView.dequeueReusableCell(withClass: PhotoPostTableViewCell.self, for: indexPath)
            }
            cell.clickableTextDelegate = self
            cell.bindData(post: post)
            return cell

        default:
            return tableView.dequeueReusableCell(withClass: ListHeadingViewCell.self, for: indexPath)
        }
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
        guard let currentFilterScope = thisViewModel.filterScope else { return }
        loadingState.onNext(.loading)
        let newFilterScope = FilterScope(
            date: currentFilterScope.date, timeUnit: currentFilterScope.timeUnit,
            section: .posts,
            filterBy: filterBy, filterValue: filterValue)

        let postListviewModel = PostListViewModel(filterScope: newFilterScope)
        navigator.show(segue: .postList(viewModel: postListviewModel), sender: self)
    }
}
