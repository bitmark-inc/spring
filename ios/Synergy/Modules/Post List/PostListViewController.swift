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

class PostListViewController: TabPageViewController {

    // MARK: - Properties
    fileprivate lazy var collectionView = PostsCollectionView()
    var posts: Results<Post>?

    // MARK: - bind ViewModel
    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? PostListViewModel else { return }
        viewModel.postsObservable
            .do(onNext: { [weak self] in
                guard let self = self else { return }
                self.posts = $0
                self.collectionView.dataSource = self
            })
            .flatMap { Observable.changeset(from: $0) }
            .subscribe(onNext: { [weak self] (_, changes) in
                guard let self = self, let changes = changes else { return }
                self.collectionView.applyChangeset(changes)
            }, onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: disposeBag)

        viewModel.getPosts()
    }

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        collectionView.delegate = self

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem(collectionView).marginTop(10).marginBottom(0).grow(1)
        }

        contentView.flex.layout(mode: .adjustHeight)
    }
}

extension PostListViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let post = posts![indexPath.row]
        let cell = collectionView.dequeueReusableCell(withClass: GeneralPostCollectionViewCell.self, for: indexPath)
        cell.bindData(post: post)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
      return Size.dw(18)
    }
}
