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
    static let shared = Storage()
    private lazy var dispatchQueue = DispatchQueue(label: "Synergy Storage", qos: .background)

    // MARK: - Handlers
    func store(_ objects: [Object]) -> Completable {
        return Completable.create { (event) -> Disposable in
            self.performSerialBackgroundWrite(writeBlock: { (backgroundRealm) in
                objects.forEach { (object) in
                    backgroundRealm.add(object, update: .modified)
                }
            }, completionBlock: { (error) in
                error != nil ? event(.error(error!)) : event(.completed)
            })

            return Disposables.create()
        }
    }

    func store(_ object: Object) -> Completable {
        Global.log.info("[start] store object")

        return Completable.create { (event) -> Disposable in
            self.performSerialBackgroundWrite(writeBlock: { (backgroundRealm) in
                backgroundRealm.add(object, update: .modified)
            }, completionBlock: { (error) in
                Global.log.info("[done] store object")
                error != nil ? event(.error(error!)) : event(.completed)
            })

            return Disposables.create()
        }
    }

    public func mainThreadUpdate(with block: @escaping (Realm) throws -> Void) -> Completable {
        Global.log.info("[start] mainThreadUpdate")

        return Completable.create { (event) -> Disposable in
            do {
                let mainRealm = try RealmConfig.currentRealm()
                try mainRealm.write {
                    try block(mainRealm)
                }
                event(.completed)
            } catch {
                event(.error(error))
            }
            return Disposables.create()
        }
    }

    private func performSerialBackgroundWrite(writeBlock: @escaping (Realm) throws -> Void,
                                              completionBlock: ((Error?) -> Void)? = nil) {
        dispatchQueue.async {
            var storageError: Error?

            do {
                let backgroundRealm = try RealmConfig.currentRealm()
                backgroundRealm.beginWrite()
                try writeBlock(backgroundRealm)
                try backgroundRealm.commitWrite()
                backgroundRealm.invalidate()
            } catch {
                storageError = error
            }

            completionBlock?(storageError)
        }
    }
}
