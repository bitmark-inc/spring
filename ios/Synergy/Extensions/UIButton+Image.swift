//
//  UIButton+Image.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

extension UIButton {
  convenience init(type: ButtonType? = nil, imageName: String) {
    if let type = type { self.init(type: type) } else { self.init() }

    let buttonImage = UIImage(named: imageName)!.original
    setImage(buttonImage, for: .normal)
    contentMode = .scaleAspectFit
  }
}
