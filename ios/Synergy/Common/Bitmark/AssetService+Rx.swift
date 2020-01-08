//
//  AssetService+Rx.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/8/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import BitmarkSDK
import RxSwift

class AssetService {
    static func getAsset(with assetId: String) -> Asset? {
        do {
            return try Asset.get(assetID: assetId)
        } catch {
            return nil
        }
    }
}

extension AssetService: ReactiveCompatible {}

struct AssetInfo {
    let registrant: Account
    let assetName: String
    let fingerprint: String
    let metadata: [String: String]
}

extension Reactive where Base: AssetService {
    static func registerAsset(assetInfo: AssetInfo) -> Single<String> {
        Global.log.info("[start] registerAsset")

        return Single.just(assetInfo)
            .map { assetInfo -> RegistrationParams in
                var metadata = assetInfo.metadata
                metadata["SOURCE"] = Constant.appName
                var assetParams = try Asset.newRegistrationParams(name: assetInfo.assetName, metadata: metadata)
                try assetParams.setFingerprint(assetInfo.fingerprint)
                try assetParams.sign(assetInfo.registrant)
                return assetParams
            }
            .flatMap { Asset.rxRegister($0) }
    }

    static func issueBitmark(issuer: Account, assetID: String) -> Single<String> {
        Global.log.info("[start] issueBitmark")

        return Single.just(assetID)
            .map { (assetId) -> IssuanceParams in
                var issueParams = try Bitmark.newIssuanceParams(assetID: assetID, quantity: 1)
                try issueParams.sign(issuer)
                return issueParams
            }
            .flatMap { Bitmark.rxIssue($0) }
            .map { $0.first ?? nil }
            .errorOnNil()
    }
}
