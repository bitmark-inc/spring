//
//  Graphs.swift
//  Synergy
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

// Array of Graphs - a property in `Group`
class Graphs {

    // MARK: - Properties
    var valueAsString: String!
    var value: [Graph]!
    let encodingRule: String.Encoding = .utf8

    // MARK: - Init
    init(from graphsStr: String) throws {
        valueAsString = graphsStr
        guard let jsonData = graphsStr.data(using: encodingRule),
            let valueAsDic = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
            else {
                throw "invalid graphs string"
        }

        value = try valueAsDic.compactMap { try Graph(from: $0) }
    }

    init(from insights: [Graph]) throws {
        self.value = insights
        let valueAsDic = insights.compactMap { $0.toDic() }

        let jsonData = try JSONSerialization.data(withJSONObject: valueAsDic)
        valueAsString = String(data: jsonData, encoding: encodingRule)
    }
}

struct Graph: Codable {
    let id: Int?
    let name: String?
    let timestamp: Date?
    let data: [GraphData]

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(Int.self, forKey: .id)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        if let timestampInterval = try values.decodeIfPresent(Double.self, forKey: .timestamp) {
            timestamp = Date(timeIntervalSince1970: timestampInterval)
        } else {
            timestamp = nil
        }
        data = try values.decode([GraphData].self, forKey: .data)
    }

    public init(from dic: [String: Any]) throws {
        self.id = dic[CodingKeys.id.stringValue] as? Int
        self.name = dic[CodingKeys.name.stringValue] as? String
        if let timestampInterval = dic[CodingKeys.timestamp.stringValue] as? Double {
            timestamp = Date(timeIntervalSince1970: timestampInterval)
        } else {
            timestamp = nil
        }

        guard let data = dic[CodingKeys.data.stringValue] as? [[String: Any]] else {
            throw "invalid graphs string"
        }
        self.data = try data.compactMap { try GraphData(from: $0) }
    }

    func toDic() -> [String: Any] {
        return [
            CodingKeys.id.stringValue: id as Any,
            CodingKeys.name.stringValue: name as Any,
            CodingKeys.timestamp.stringValue: timestamp?.timeIntervalSince1970 as Any,
            CodingKeys.data.stringValue: data.compactMap { $0.toDic() }
        ]
    }
}

struct GraphData: Codable {
    let quantity, categoryID: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case quantity, name
        case categoryID = "category_id"
    }

    public init(from dic: [String: Any]) throws {
        guard let quantity = dic[CodingKeys.quantity.stringValue] as? Int,
            let name = dic[CodingKeys.name.stringValue] as? String,
            let categoryID = dic[CodingKeys.categoryID.stringValue] as? Int
            else {
                throw "invalid graphs string"
        }
        self.quantity = quantity
        self.name = name
        self.categoryID = categoryID
    }

    func toDic() -> [String: Any] {
        return [
            CodingKeys.quantity.stringValue: quantity,
            CodingKeys.name.stringValue: name,
            CodingKeys.categoryID.stringValue: categoryID
        ]
    }
}

enum GroupKey: String {
    case type
    case day
    case friend
    case place
}
