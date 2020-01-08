//
//  ArchiveDataEngine+Rx.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/8/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import RealmSwift
import RxSwift

class ArchiveDataEngine {}

extension ArchiveDataEngine: ReactiveCompatible {}

extension Reactive where Base: ArchiveDataEngine {

    static func store(_ archives: [Archive]) -> Completable {
        return RealmConfig.rxCurrentRealm()
            .flatMapCompletable { (realm) -> Completable in
                guard let archiveProperties = realm.schema["Archive"]?.properties else {
                    return Completable.never()
                }

                let updateArchiveProperties = archiveProperties.filter { $0.name != "issueBitmark" }

                return Completable.create { (event) -> Disposable in
                    autoreleasepool { () -> Disposable in
                        for archive in archives {
                            var archivePropertyValues = [String: Any]()
                            updateArchiveProperties.forEach { archivePropertyValues[$0.name] = archive[$0.name] }
                            do {
                                try realm.write {
                                    realm.create(Archive.self, value: archivePropertyValues, update: .modified)
                                }
                            } catch {
                                event(.error(error))
                            }
                        }

                        event(.completed)
                        return Disposables.create()
                    }
                }

            }
    }

    static func issueBitmarkIfNeeded() -> Completable {
        return Completable.deferred {
            guard let account = Global.current.account else {
                return Completable.never()
            }

            return RealmConfig.rxCurrentRealm()
                .flatMapCompletable { (realm) -> Completable in
                    return Completable.create { (event) -> Disposable in
                        for archive in realm.objects(Archive.self)
                            .filter({ !$0.issueBitmark && $0.status == ArchiveStatus.processed.rawValue }) {
                                guard let assetID = RegistrationParams.computeAssetId(fingerprint: archive.contentHash),
                                    AssetService.getAsset(with: assetID) == nil
                                    else {
                                        continue
                                }

                                let assetInfo = AssetInfo(
                                    registrant: account,
                                    assetName: archive.contentHash, fingerprint: archive.contentHash, metadata: [:])

                                _ = AssetService.rx.registerAsset(assetInfo: assetInfo)
                                    .flatMap { AssetService.rx.issueBitmark(issuer: account, assetID: $0) }
                                    .subscribe(onSuccess: { (_) in
                                        autoreleasepool {
                                            do {
                                                try realm.write {
                                                    archive.issueBitmark = true
                                                }
                                            } catch {
                                                Global.log.error(error)
                                            }
                                        }
                                    }, onError: { (error) in
                                        Global.log.error(error)
                                    })
                            }

                        event(.completed)
                        return Disposables.create()
                    }
                }
        }
    }
}
