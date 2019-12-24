//
//  Groups.swift
//  Synergy
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

class GroupsConverter {

    // MARK: - Properties
    var valueAsString: String!
    var value: Groups
    let encodingRule: String.Encoding = .utf8

    // MARK: - Init
    init(from value: String) throws {
        valueAsString = value

        guard let jsonData = valueAsString.data(using: encodingRule)
            else {
                throw "invalid groups string"
        }
        self.value = try JSONDecoder().decode(Groups.self, from: jsonData)
    }

    init(from value: Groups) throws {
        self.value = value

        let jsonData = try JSONEncoder().encode(value)
        valueAsString = String(data: jsonData, encoding: encodingRule)
    }
}

struct Groups: Codable {

    // MARK: - Properties
    let type: GraphData
    let subPeriod: [GraphData]?
    let friend: [GraphData]?
    let place: [GraphData]?

    enum CodingKeys: String, CodingKey {
        case type, friend, place
        case subPeriod = "sub_period"
    }

    // MARK: - Init
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(GraphData.self, forKey: .type)
        subPeriod = try values.decodeIfPresent([GraphData].self, forKey: .subPeriod)
        friend = try values.decodeIfPresent([GraphData].self, forKey: .friend)
        place = try values.decodeIfPresent([GraphData].self, forKey: .place)
    }
}

struct GraphData: Codable {
    let name: String?
    let data: [String: Double]
}

enum GroupKey: String {
    case type
    case day
    case friend
    case place
}
