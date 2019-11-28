//
//  UsageCollectionView.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/28/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import Charts

class UsageCollectionView: UICollectionView {
    private let disposeBag = DisposeBag()
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        super.init(frame: CGRect.zero, collectionViewLayout: layout)
        
        self.dataSource = self
        self.delegate = self
        self.register(cellWithClass: UsageHeadingCollectionViewCell.self)
        
        themeService.rx
            .bind({ $0.controlBackgroundColor }, to: rx.backgroundColor)
        .disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension UsageCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withClass: UsageHeadingCollectionViewCell.self, for: indexPath)
    }
}

extension UsageCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.width, height: 62)
    }
}

class UsageHeadingCollectionViewCell: UICollectionViewCell {
    private let countLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 24))
    private let actionDescriptionLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 10))
    private let changedDescriptionLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 10))
    private let averageDescriptionLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 10))
    
    lazy var updownImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Declare subviews
        let toplineView = UIView()
        toplineView.flex.direction(.row).define { (flex) in
            flex.alignItems(.start)
            flex.addItem(countLabel)
            flex.addItem(actionDescriptionLabel).marginLeft(4)
        }
        
        let bottomLineView = UIView()
        bottomLineView.flex.direction(.row).define { (flex) in
            flex.alignItems(.center)
            flex.addItem(updownImageView)
            flex.addItem(changedDescriptionLabel).marginLeft(4)
            flex.addItem(averageDescriptionLabel).marginLeft(5)
        }
        contentView.flex.direction(.column).define { (flex) in
            flex.addItem(toplineView)
            flex.addItem(bottomLineView)
        }
        
        bindData()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func bindData() {
        countLabel.text = "24 POSTS"
        actionDescriptionLabel.text = "you made"
        changedDescriptionLabel.text = "5% from last decade"
        averageDescriptionLabel.text = "Decade average = 20"
        updownImageView.image = R.image.usage_up()
    }
}
