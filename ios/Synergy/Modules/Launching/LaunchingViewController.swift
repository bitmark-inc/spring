//
//  LaunchingViewController.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import RxSwift
import RxCocoa

class LaunchingViewController: ViewController {

    lazy var thisViewModel = { viewModel as! LaunchingViewModel }()

    override func bindViewModel() {
        super.bindViewModel()

        Account.rx.existsCurrentAccount()
            .observeOn(MainScheduler.instance)
            .do(onSuccess: { Global.current.account = $0 })
            .flatMapCompletable { [weak self] in
                guard let self = self else { return Completable.never() }
                return try self.prepareAndGotoNext(account: $0)
        }
        .subscribe(
            onError: { (error) in
                Global.log.error(error)
        }
        )
            .disposed(by: disposeBag)
    }

    func prepareAndGotoNext(account: Account?) throws -> Completable {
        if account != nil {
            try RealmConfig.setupDBForCurrentAccount()
            self.thisViewModel.gotoSignInScreen()
        } else {
            self.thisViewModel.gotoSignInWallScreen()
        }
        return Completable.empty()
    }
}
