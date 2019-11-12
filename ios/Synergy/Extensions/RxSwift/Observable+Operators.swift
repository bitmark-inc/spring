//
//  Observable+Operators.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

infix operator => : DefaultPrecedence
infix operator <=> : DefaultPrecedence

func => <Base>(textInput: TextInput<Base>, variable: BehaviorRelay<String>) -> Disposable {

  let bindToVariable = textInput.text
    .filterNil()
    .subscribe(onNext: { variable.accept($0) })

  return Disposables.create([bindToVariable])
}

func <=> <Base>(textInput: TextInput<Base>, variable: BehaviorRelay<String>) -> Disposable {
    let bindToUIDisposable = variable.asObservable()
        .bind(to: textInput.text)

    let bindToVariable = textInput.text
      .filterNil()
      .subscribe(onNext: { variable.accept($0) })

    return Disposables.create(bindToUIDisposable, bindToVariable)
}
