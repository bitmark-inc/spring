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
    fileprivate lazy var collectionView = PostsCollectionView()
    fileprivate lazy var emptyView = makeEmptyView()
    var posts: Results<Post>?
    lazy var thisViewModel = viewModel as? PostListViewModel

    // MARK: - bind ViewModel
    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? PostListViewModel else { return }

        setThemedScreenTitle(text: viewModel.screenTitleFromFilter)

        viewModel.postsObservable
            .subscribe(onNext: { [weak self] (realmPosts) in
                guard let self = self else { return }
                self.posts = realmPosts
                self.collectionView.dataSource = self

                self.emptyView.isHidden = !realmPosts.isEmpty
                self.collectionView.isHidden = realmPosts.isEmpty

                Observable.changeset(from: realmPosts)
                    .subscribe(onNext: { [weak self] (_, changes) in
                        guard let self = self, let changes = changes else { return }

                        self.emptyView.isHidden = !realmPosts.isEmpty
                        self.collectionView.isHidden = realmPosts.isEmpty

                        self.collectionView.applyChangeset(changes)
                    }, onError: { (error) in
                        Global.log.error(error)
                    })
                    .disposed(by: self.disposeBag)

            })
            .disposed(by: disposeBag)

        viewModel.getPosts()
    }

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        collectionView.delegate = self
        screenTitleLabel.text = "ABCDDEBS"

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem(emptyView).marginTop(35)
            flex.addItem(collectionView).marginTop(10).marginBottom(0).grow(1)
        }

        contentView.flex.layout(mode: .adjustHeight)
    }

    fileprivate func makeEmptyView() -> Label {
        let label = Label()
        label.isDescription = true
        label.applyBlack(text: R.string.phrase.postsEmpty(), font: R.font.atlasGroteskRegular(size: Size.ds(32)))
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
        let cell = collectionView.dequeueReusableCell(withClass: GeneralPostCollectionViewCell.self, for: indexPath)
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
