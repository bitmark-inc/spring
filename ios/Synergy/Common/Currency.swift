//
//  Currency.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

enum Currency: String, CaseIterable {

    static var `default`: Currency = .USD

    case USD, AED, ALL, AMD, ANG, AUD, AWG, AZN, BAM, BBD, BDT, BGN, BIF, BMD, BND, BSD, BWP, BZD,
    CAD, CDF, CHF, CNY, DKK, DOP, DZD, EGP, ETB, EUR, FJD, GBP, GEL, GIP, GMD, GYD, HKD, HRK,
    HTG, IDR, ILS, ISK, JMD, JPY, KES, KGS, KHR, KMF, KRW, KYD, KZT, LBP, LKR, LRD, LSL, MAD,
    MDL, MGA, MKD, MMK, MNT, MOP, MRO, MVR, MWK, MXN, MYR, MZN, NAD, NGN, NOK, NPR, NZD, PGK,
    PHP, PKR, PLN, QAR, RON, RSD, RUB, RWF, SAR, SBD, SCR, SEK, SGD, SLL, SOS, SZL, THB, TJS,
    TOP, TRY, TTD, TWD, TZS, UAH, UGX, UZS, VND, VUV, WST, XAF, XCD, YER, ZAR, ZMW

    static let currenciesWithNoDecimal: [Currency] = [
        .BIF, .JPY, .KMF, .KRW, .MGA, .RWF, .UGX, .VND, .VUV, .XAF
    ]

    // Stripe API expect currency's smallest unit; ex: cents
    // https://stripe.com/docs/currencies#zero-decimal
    var fractionalNumberToSmallestUnit: Double {
        return Self.currenciesWithNoDecimal.contains(self) ? 1 : 100
    }

    var minimumPriceInCents: Int {
        return minimumPrice * Int(fractionalNumberToSmallestUnit)
    }

    var maximumPriceInCents: Int {
        return 1_000_000 * exchangeRange * Int(fractionalNumberToSmallestUnit)
    }

    // minumumPrice is has value as exchange rate
    fileprivate var exchangeRange: Int {
        return minimumPrice
    }

    fileprivate var minimumPrice: Int {
        switch self {
        case .AED: return 4
        case .ALL: return 112
        case .AMD: return 475
        case .ANG: return 2
        case .AUD: return 2
        case .AWG: return 2
        case .AZN: return 2
        case .BAM: return 2
        case .BBD: return 2
        case .BDT: return 85
        case .BGN: return 2
        case .BIF: return 1862
        case .BMD: return 1
        case .BND: return 2
        case .BSD: return 1
        case .BWP: return 11
        case .BZD: return 3
        case .CAD: return 2
        case .CDF: return 1649
        case .CHF: return 1
        case .CNY: return 8
        case .DKK: return 7
        case .DOP: return 53
        case .DZD: return 120
        case .EGP: return 17
        case .ETB: return 30
        case .EUR: return 1
        case .FJD: return 3
        case .GBP: return 1
        case .GEL: return 3
        case .GIP: return 1
        case .GMD: return 52
        case .GYD: return 209
        case .HKD: return 8
        case .HRK: return 7
        case .HTG: return 97
        case .IDR: return 13991
        case .ILS: return 4
        case .ISK: return 125
        case .JMD: return 138
        case .JPY: return 109
        case .KES: return 104
        case .KGS: return 70
        case .KHR: return 4041
        case .KMF: return 444
        case .KRW: return 1170
        case .KYD: return 1
        case .KZT: return 388
        case .LBP: return 1509
        case .LKR: return 182
        case .LRD: return 212
        case .LSL: return 15
        case .MAD: return 10
        case .MDL: return 18
        case .MGA: return 3696
        case .MKD: return 56
        case .MMK: return 1526
        case .MNT: return 2676
        case .MOP: return 9
        case .MRO: return 357
        case .MVR: return 16
        case .MWK: return 732
        case .MXN: return 20
        case .MYR: return 5
        case .MZN: return 63
        case .NAD: return 15
        case .NGN: return 361
        case .NOK: return 10
        case .NPR: return 114
        case .NZD: return 2
        case .PGK: return 4
        case .PHP: return 52
        case .PKR: return 156
        case .PLN: return 4
        case .QAR: return 4
        case .RON: return 5
        case .RSD: return 106
        case .RUB: return 64
        case .RWF: return 915
        case .SAR: return 4
        case .SBD: return 9
        case .SCR: return 14
        case .SEK: return 10
        case .SGD: return 2
        case .SLL: return 7439
        case .SOS: return 578
        case .SZL: return 15
        case .THB: return 31
        case .TJS: return 10
        case .TOP: return 3
        case .TRY: return 6
        case .TTD: return 7
        case .TWD: return 31
        case .TZS: return 2298
        case .UAH: return 26
        case .UGX: return 3691
        case .USD: return 1
        case .UZS: return 9431
        case .VND: return 23147
        case .VUV: return 117
        case .WST: return 3
        case .XAF: return 591
        case .XCD: return 3
        case .YER: return 251
        case .ZAR: return 15
        case .ZMW: return 14
        }
    }
}
