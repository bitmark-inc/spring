//
//  RxOptional+Single+Optional.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxOptional

extension PrimitiveSequence where Trait == SingleTrait, Element: OptionalType {
    func errorOnNil(_ error: Error = RxOptionalError.foundNilWhileUnwrappingOptional(Element.self)) -> Single<Element.Wrapped> {
        return self.map { element -> Element.Wrapped in
            guard let value = element.value else {
                throw error
            }
            return value
        }
    }
}
