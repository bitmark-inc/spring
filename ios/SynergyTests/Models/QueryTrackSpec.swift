//
//  QueryTrackSpec.swift
//  SynergyTests
//
//  Created by Thuyen Truong on 1/2/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Quick
import Nimble
import SwiftDate

@testable import Synergy

class QueryTrackSpec: QuickSpec {

    override func spec() {
        let value = QueryTrack()

        describe(".removeQueriedPeriod") {
            var result: DatePeriod?
            var datePeriod: DatePeriod!
            let testFunction = { result = value.removeQueriedPeriod(for: datePeriod) }

            context("values is empty") {
                beforeEach {
                    value.datePeriodsStr = ""
                    datePeriod = makeDatePeriod("2019-02-02", "2019-04-05")
                    testFunction()
                }

                it("datePeriod is not changed") {
                    expect(result).to(equal(datePeriod))
                }
            }

            context("values has elements") {
                beforeEach {
                    let datePeriods = [
                        makeDatePeriod("2019-02-02", "2019-04-05"),
                        makeDatePeriod("2019-08-01", "2019-08-31")
                    ]
                    value.datePeriodsStr = try! datePeriods.asString()
                }

                context("new value is not overlapped") {
                    beforeEach {
                        datePeriod = makeDatePeriod("2019-01-02", "2019-01-10")
                        testFunction()
                    }

                    it("datePeriod is not changed") {
                        expect(result).to(equal(datePeriod))
                    }
                }

                context("new value is included") {
                    beforeEach {
                        datePeriod = makeDatePeriod("2019-02-10", "2019-03-03")
                        testFunction()
                    }

                    it("result is nil") {
                        expect(result).to(beNil())
                    }
                }

                context("new value is same as one element") {
                    beforeEach {
                        datePeriod = makeDatePeriod("2019-08-01", "2019-08-31")
                        testFunction()
                    }

                    it("result is nil") {
                        expect(result).to(beNil())
                    }
                }

                context("new value includes one element") {
                    beforeEach {
                        datePeriod = makeDatePeriod("2019-01-10", "2019-04-10")
                        testFunction()
                    }

                    it("datePeriod is not changed") {
                        expect(result).to(equal(datePeriod))
                    }
                }

                context("new value includes two elements") {
                    beforeEach {
                        datePeriod = makeDatePeriod("2019-01-10", "2019-09-12")
                        testFunction()
                    }

                    it("datePeriod is not changed") {
                        expect(result).to(equal(datePeriod))
                    }
                }

                context("new value is overlapped one element") {
                    beforeEach {
                        datePeriod = makeDatePeriod("2019-01-10", "2019-03-05")
                        testFunction()
                    }

                    it("datePeriod is shortened") {
                        expect(result).to(equal(makeDatePeriod("2019-01-10", "2019-02-01")) )
                    }
                }

                context("new value is overlapped 2 elements") {
                    beforeEach {
                        datePeriod = makeDatePeriod("2019-03-03", "2019-08-20")
                        testFunction()
                    }

                    it("datePeriod is shortened") {
                        expect(result).to(equal(makeDatePeriod("2019-04-06", "2019-07-31")) )
                    }
                }

                context("new value is overlapped one element in the left") {
                    beforeEach {
                        datePeriod = makeDatePeriod("2019-02-02", "2019-06-07")
                        testFunction()
                    }

                    it("datePeriod is shortened") {
                        expect(result).to(equal(makeDatePeriod("2019-04-06", "2019-06-07")) )
                    }
                }

                context("new value is overlapped one element in the right") {
                    beforeEach {
                        datePeriod = makeDatePeriod("2018-06-20", "2019-04-05")
                        testFunction()
                    }

                    it("datePeriod is shortened") {
                        expect(result).to(equal(makeDatePeriod("2018-06-20", "2019-02-01")))
                    }
                }
            }
        }
    }
}
