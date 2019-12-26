//
//  ReactionListViewController.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/26/19.
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

class ReactionListViewController: ViewController, BackNavigator {

    // MARK: - Properties
    fileprivate lazy var tableView = ReactionTableView()
    fileprivate lazy var emptyView = makeEmptyView()
    fileprivate lazy var backItem = makeBlackBackItem()

    var reactions: Results<Reaction>?
    lazy var thisViewModel = viewModel as! ReactionListViewModel

    // MARK: - bind ViewModel
    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? ReactionListViewModel else { return }

        viewModel.reactionsObservable
            .subscribe(onNext: { [weak self] (realmReactions) in
                guard let self = self else { return }
                self.reactions = realmReactions
                self.tableView.reloadData()
                self.refreshView()

                Observable.changeset(from: realmReactions)
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

        viewModel.getReactions()
    }

    func refreshView() {
        let hasReactions = reactions != nil && !reactions!.isEmpty
        emptyView.isHidden = hasReactions
        tableView.isScrollEnabled = hasReactions
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
                    .top(150).left(OurTheme.paddingInset.left)
            }
    }

    fileprivate func makeEmptyView() -> Label {
        let label = Label()
        label.isDescription = true
        label.apply(
            text: R.string.phrase.reactionsEmpty(),
            font: R.font.atlasGroteskLight(size: Size.ds(32)),
            colorTheme: .black)
        label.isHidden = true
        return label
    }
}

extension ReactionListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:     return 1
        case 1:     return reactions?.count ?? 0
        default:    return 0
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
            let reaction = reactions![indexPath.row]
            let cell = tableView.dequeueReusableCell(withClass: ReactionTableViewCell.self, for: indexPath)
            cell.bindData(reaction: reaction)
            return cell

        default:
            return tableView.dequeueReusableCell(withClass: ListHeadingViewCell.self, for: indexPath)
        }
    }
}
