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

    func fetchOverallArchiveStatus() -> Single<ArchiveStatus?> {
        return Single.create { (event) -> Disposable in
            _ = FBArchiveService.getAll()
                .subscribe(onSuccess: { (archives) in
                    guard archives.count > 0 else {
                        event(.success(nil))
                        return
                    }

                    if archives.firstIndex(where: { $0.status == ArchiveStatus.processed.rawValue }) != nil {
                        event(.success(.processed))
                    } else {
                        let notInvalidArchives = archives.filter { $0.status != ArchiveStatus.invalid.rawValue }
                        event(.success( notInvalidArchives.isEmpty ? .invalid : .submitted ))
                    }
                }, onError: { (error) in
                    event(.error(error))
                })

            return Disposables.create()
        }
    }
}
