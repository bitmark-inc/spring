//
//  ArrayStringSpec.swift
//  SynergyTests
//
//  Created by Thuyen Truong on 1/6/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Quick
import Nimble

@testable import Synergy

class ArrayStringSpec: QuickSpec {

    override func spec() {
        var value: [String]!

        describe(".toFriendsSentence") {
            var result: String!
            let testFunction = { result = value.toFriendsSentence() }

            context("value is one friend") {
                beforeEach {
                    value = ["Phil Lin"]
                    testFunction()
                }

                it("result is as expected") {
                    expect(result).to(equal("Phil Lin"))
                }
            }

            context("value is 2 friends") {
                beforeEach {
                    value = ["Phil Lin", "Mars Chen"]
                    testFunction()
                }

                it("result is as expected") {
                    expect(result).to(equal("Phil Lin & Mars Chen"))
                }
            }

            context("value is 3 friends") {
                beforeEach {
                    value = ["Phil Lin", "Mars Chen", "Sunny"]
                    testFunction()
                }

                it("result is as expected") {
                    expect(result).to(equal("Phil Lin, Mars Chen and Sunny"))
                }
            }

            context("value is more than 3 friends") {
                beforeEach {
                    value = ["Phil Lin", "Mars Chen", "Sunny", "Tom"]
                    testFunction()
                }

                it("result is as expected") {
                    expect(result).to(equal("Phil Lin, Mars Chen and 2 others"))
                }
            }
        }
    }
}
