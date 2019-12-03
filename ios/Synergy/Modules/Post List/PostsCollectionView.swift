//
//  PostsCollectionView.swift
//  Synergy
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift
import Realm

class PostsCollectionView: CollectionView {

    // MARK: - Properties
    private let disposeBag = DisposeBag()

    override init() {
        super.init()

        self.register(cellWithClass: GeneralPostCollectionViewCell.self)

        themeService.rx
            .bind({ $0.background }, to: rx.backgroundColor)
        .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
