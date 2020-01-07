//
//  Storage.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

class Storage {

    // MARK: - Properties
    static private var dispatchQueue = DispatchQueue(label: "Synergy Storage", qos: .background)
    static private var notificationToken: NotificationToken?

    // MARK: - Handlers
    static func store(_ objects: [Object], inGlobalRealm: Bool = false) -> Completable {
        return Completable.create { (event) -> Disposable in
            autoreleasepool {
                self.performWrite(inGlobalRealm: inGlobalRealm, writeBlock: { (backgroundRealm) in
                    objects.forEach { (object) in
                        backgroundRealm.add(object, update: .modified)
                    }
                }, completionBlock: { (error) in
                    error != nil ? event(.error(error!)) : event(.completed)
                })
            }

            return Disposables.create()
        }
    }

    static func store(_ object: Object, inGlobalRealm: Bool = false) -> Completable {
        Global.log.info("[start] store object")

        return Completable.create { (event) -> Disposable in
            autoreleasepool {
                self.performWrite(inGlobalRealm: inGlobalRealm, writeBlock: { (backgroundRealm) in
                    backgroundRealm.add(object, update: .modified)
                }, completionBlock: { (error) in
                    Global.log.info("[done] store object")
                    error != nil ? event(.error(error!)) : event(.completed)
                })
            }

            return Disposables.create()
        }
    }

    static private func performWrite(inGlobalRealm: Bool = false, writeBlock: @escaping (Realm) throws -> Void,
                                              completionBlock: ((Error?) -> Void)? = nil) {
        DispatchQueue.main.async {
            var storageError: Error?

            autoreleasepool {
                do {

                    let backgroundRealm = try inGlobalRealm ? RealmConfig.globalRealm() : RealmConfig.currentRealm()
                    self.notificationToken = backgroundRealm.observe { (notification, realm) in
                        completionBlock?(storageError)
                        self.notificationToken?.invalidate()
                    }

                    backgroundRealm.beginWrite()
                    try writeBlock(backgroundRealm)
                    try backgroundRealm.commitWrite()
                } catch {
                    storageError = error
                }
            }

        }
    }
}
