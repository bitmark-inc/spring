//
//  LaunchingViewModel.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift

class LaunchingViewModel: ViewModel {

    func checkIsArchivesFailed() -> Single<Bool> {
        return Single.create { (event) -> Disposable in
            _ = FBArchiveService.getAll()
                .subscribe(onSuccess: { (archives) in
                    let notInvalidArchives = archives.filter { $0.status != ArchiveStatus.invalid.rawValue }
                    event(.success(notInvalidArchives.isEmpty))
                }, onError: { (error) in
                    event(.error(error))
                })

            return Disposables.create()
        }
    }
}
