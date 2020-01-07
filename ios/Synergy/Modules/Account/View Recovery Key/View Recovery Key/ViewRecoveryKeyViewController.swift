//
//  ViewRecoveryKeyViewController.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import UPCarouselFlowLayout

class ViewRecoveryKeyViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var screenTitle = makeScreenTitle()
    lazy var recoveryKeyCollectionView = makeRecoveryKeyCollectionView()
    lazy var indexWordLabel = makeIndexWordLabel()

    var recoveryKey = [String]()
    var currentViewWordRelay = BehaviorRelay(value: 1)

    fileprivate var pageSize: CGSize {
        let layout = self.recoveryKeyCollectionView.collectionViewLayout as! UPCarouselFlowLayout
        var pageSize = layout.itemSize
        pageSize.width += layout.minimumLineSpacing
        return pageSize
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? ViewRecoveryKeyViewModel else { return }

        viewModel.currentRecoveryKeyRelay
            .subscribe(onNext: { [weak self] in self?.recoveryKey = $0 })
            .disposed(by: disposeBag)

        currentViewWordRelay
            .map { R.string.phrase.accountRecoveryKeyIndex("\($0)") }
            .bind(to: indexWordLabel.rx.text)
            .disposed(by: disposeBag)
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()

        let descriptionLabel = Label()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.apply(
            text: R.string.phrase.accountRecoveryKeyOutputGuide(),
            font: R.font.atlasGroteskThin(size: Size.ds(22)),
            colorTheme: .tundora, lineHeight: 1.32)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column)
            .define { (flex) in
                flex.addItem(blackBackItem)
                flex.addItem(screenTitle).padding(OurTheme.accountPaddingScreenTitleInset)
                flex.addItem(descriptionLabel)
                flex.addItem(recoveryKeyCollectionView).height(200)
                flex.addItem(indexWordLabel).width(100%)
            }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension ViewRecoveryKeyViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recoveryKey.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: RecoveryKeyWordCell.self, for: indexPath)
        let word = recoveryKey[indexPath.row]
        cell.setData(word: word)
        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let layout = self.recoveryKeyCollectionView.collectionViewLayout as? UPCarouselFlowLayout else { return }
        let pageSide = (layout.scrollDirection == .horizontal) ? self.pageSize.width : self.pageSize.height
        let offset = scrollView.contentOffset.x
        let currentViewIndex = Int(floor((offset - pageSide / 2) / pageSide) + 1)
        currentViewWordRelay.accept(currentViewIndex + 1)
    }
}

extension ViewRecoveryKeyViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.applyTitleTheme(
            text: R.string.phrase.accountRecoveryKeyTitle().localizedUppercase,
            colorTheme: OurTheme.accountColorTheme)
        return label
    }

    fileprivate func makeRecoveryKeyCollectionView() -> CollectionView {
        let flowlayout = UPCarouselFlowLayout()
        flowlayout.scrollDirection = .horizontal
        flowlayout.itemSize = CGSize(width: 200, height: 64)

        let collectionView = CollectionView()
        collectionView.collectionViewLayout = flowlayout
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.register(cellWithClass: RecoveryKeyWordCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }

    fileprivate func makeIndexWordLabel() -> Label {
        let label = Label()
        label.textAlignment = .center
        label.apply(text: "", font: R.font.atlasGroteskLight(size: Size.ds(22)), colorTheme: .tundora, lineHeight: 1.32)
        return label
    }
}
