//
//  Insight.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/9/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation

struct Insight: Codable {
    let fbIncome: Double
    let fbIncomeFromInterval: Double

    enum CodingKeys: String, CodingKey {
        case fbIncome = "fb_income"
        case fbIncomeFromInterval = "fb_income_from"
    }

    // MARK: - Init
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fbIncome = try values.decode(Double.self, forKey: .fbIncome)
        fbIncomeFromInterval = try values.decode(Double.self, forKey: .fbIncomeFromInterval)
    }
}

extension Insight {
    var fbIncomeFrom: Date {
        return Date(timeIntervalSince1970: fbIncomeFromInterval)
    }
}

class InsightConverter {

    // MARK: - Properties
    var valueAsString: String!
    var value: Insight
    let encodingRule: String.Encoding = .utf8

    // MARK: - Init
    init(from value: String) throws {
        valueAsString = value

        guard let jsonData = valueAsString.data(using: encodingRule)
            else {
                throw "invalid insight string"
        }
        self.value = try JSONDecoder().decode(Insight.self, from: jsonData)
    }

    init(from value: Insight) throws {
        self.value = value

        let jsonData = try JSONEncoder().encode(value)
        valueAsString = String(data: jsonData, encoding: encodingRule)
    }
}
