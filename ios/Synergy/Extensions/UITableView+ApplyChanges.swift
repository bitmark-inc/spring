//
//  UITableView+ApplyChanges.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxRealm

extension UITableView {
    func applyChangeset(_ changes: RealmChangeset, section: Int) {
        beginUpdates()
        deleteRows(at: changes.deleted.map { IndexPath(row: $0, section: section) }, with: .automatic)
        insertRows(at: changes.inserted.map { IndexPath(row: $0, section: section) }, with: .automatic)
        reloadRows(at: changes.updated.map { IndexPath(row: $0, section: section) }, with: .automatic)
        endUpdates()
    }
}

extension UICollectionView {
    func applyChangeset(_ changes: RealmChangeset) {
        performBatchUpdates({
            deleteItems(at: changes.deleted.map { IndexPath(row: $0, section: 0) })
            insertItems(at: changes.inserted.map { IndexPath(row: $0, section: 0) })
            reloadItems(at: changes.updated.map { IndexPath(row: $0, section: 0) })
        })
    }
}
