//
//  Converter.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/13/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation

class Converter<T: Codable>  {

    // MARK: - Properties
    var valueAsString: String!
    var value: T
    let encodingRule: String.Encoding = .utf8

    // MARK: - Init
    init(from value: String) throws {
        valueAsString = value

        guard let jsonData = valueAsString.data(using: encodingRule)
            else {
                throw "invalid valueAsString"
        }
        self.value = try JSONDecoder().decode(T.self, from: jsonData)
    }

    init(from value: T) throws {
        self.value = value

        let jsonData = try JSONEncoder().encode(value)
        valueAsString = String(data: jsonData, encoding: encodingRule)
    }
}
