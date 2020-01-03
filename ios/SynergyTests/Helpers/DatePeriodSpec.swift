//
//  DatePeriodSpec.swift
//  SynergyTests
//
//  Created by Thuyen Truong on 1/2/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Quick
import Nimble
import SwiftDate

@testable import Synergy

class DatePeriodSpec: QuickSpec {

    override func spec() {
        var value: DatePeriod!

        describe(".isLinked") {
            var result: Bool!
            var otherDatePeriod: DatePeriod!
            let testFunction = { result = value.isLinked(with: otherDatePeriod) }

            beforeEach {
                value = makeDatePeriod("2019-01-01", "2019-01-31")
            }

            context("value is linked with other datePeriod") {
                beforeEach {
                    otherDatePeriod = makeDatePeriod("2019-02-01", "2019-02-10")
                    testFunction()
                }

                it("result is true") {
                    expect(result).to(equal(true))
                }
            }

            context("value is not linked with other datePeriod") {
                beforeEach {
                    otherDatePeriod = makeDatePeriod("2010-01-01", "2010-05-10")
                    testFunction()
                }

                it("result is false") {
                    expect(result).to(equal(false))
                }
            }
        }
    }
}

class ArrayOfDatePeriodSpec: QuickSpec {
    override func spec() {
        var value: [DatePeriod]!

        describe(".add(newDatePeiod)") {
            var newDatePeriod: DatePeriod!
            var result: [DatePeriod]!

            let testFunction = { result = value.add(newDatePeriod: newDatePeriod) }

            context("values is empty") {
                beforeEach {
                    value = []
                    newDatePeriod = makeDatePeriod("2019-02-02", "2019-03-01")
                    testFunction()
                }

                it("new value is added") {
                    expect(result).to(equal([newDatePeriod]))
                }
            }

            context("values has elements") {
                beforeEach {
                    value = [
                        makeDatePeriod("2019-02-02", "2019-04-05"),
                        makeDatePeriod("2019-08-01", "2019-08-31")
                    ]
                }

                context("new value is not related") {
                    beforeEach {
                        newDatePeriod = makeDatePeriod("2019-10-10", "2019-10-20")
                        testFunction()
                    }

                    it("new value is added") {
                        expect(result.count).to(equal(3))
                        expect(result).to(contain(newDatePeriod))
                    }
                }

                context("new value is included") {
                    beforeEach {
                        newDatePeriod = makeDatePeriod("2019-02-10", "2019-03-03")
                        testFunction()
                    }

                    it("result is not changed") {
                        expect(result.count).to(equal(2))
                        expect(result).to(contain(value))
                    }
                }

                context("new value is same as one element") {
                    beforeEach {
                        newDatePeriod = makeDatePeriod("2019-08-01", "2019-08-31")
                        testFunction()
                    }

                    it("result is not changed") {
                        expect(result.count).to(equal(2))
                        expect(result).to(contain(value))
                    }
                }

                context("new value includes one element") {
                    beforeEach {
                        newDatePeriod = makeDatePeriod("2019-01-10", "2019-04-10")
                        testFunction()
                    }

                    it("new value is linked with the element") {
                        expect(result.count).to(equal(2))
                        expect(result).to(contain([
                            makeDatePeriod("2019-01-10", "2019-04-10"),
                            makeDatePeriod("2019-08-01", "2019-08-31")
                        ]))
                    }
                }

                context("new value includes two elements") {
                    beforeEach {
                        newDatePeriod = makeDatePeriod("2019-01-10", "2019-09-12")
                        testFunction()
                    }

                    it("new value is linked with elements") {
                        expect(result).to(equal([
                            makeDatePeriod("2019-01-10", "2019-09-12")
                        ]))
                    }
                }

                context("new value is overlapped one element") {
                    beforeEach {
                        newDatePeriod = makeDatePeriod("2019-01-10", "2019-03-05")
                        testFunction()
                    }

                    it("new value is added and adjust new values") {
                        expect(result.count).to(equal(2))
                        expect(result).to(contain([
                            makeDatePeriod("2019-01-10", "2019-04-05"),
                            makeDatePeriod("2019-08-01", "2019-08-31")
                        ]))
                    }
                }

                context("new value is overlapped 2 elements") {
                    beforeEach {
                        newDatePeriod = makeDatePeriod("2019-03-03", "2019-08-20")
                        testFunction()
                    }

                    it("new value is linked with elements") {
                        expect(result).to(equal([
                            makeDatePeriod("2019-02-02", "2019-08-31")
                        ]))
                    }
                }

                context("new value is linked one element") {
                    beforeEach {
                        newDatePeriod = makeDatePeriod("2019-04-06", "2019-07-07")
                        testFunction()
                    }

                    it("new value is added and linked with elements") {
                        expect(result.count).to(equal(2))
                        expect(result).to(contain([
                            makeDatePeriod("2019-02-02", "2019-07-07"),
                            makeDatePeriod("2019-08-01", "2019-08-31")
                        ]))
                    }
                }

                context("new value is linked 2 elements") {
                    beforeEach {
                        newDatePeriod = makeDatePeriod("2019-04-05", "2019-07-31")
                        testFunction()
                    }

                    it("new value is added and linked with elements") {
                        expect(result).to(equal([
                            makeDatePeriod("2019-02-02", "2019-08-31")
                        ]))
                    }
                }
            }
        }
    }
}

internal func makeDatePeriod(_ startDate: String, _ endDate: String) -> DatePeriod {
    return DatePeriod(
        startDate: Date(startDate)!.dateAtStartOf(.day),
        endDate: Date(endDate)!.dateAtEndOf(.day))
}
