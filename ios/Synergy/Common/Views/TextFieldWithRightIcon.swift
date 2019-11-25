//
//  TextFieldWithRightIcon.swift
//  Synergy
//
//  Created by thuyentruong on 11/21/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class TextFieldWithRightIcon: TextField {
    let padding: CGFloat = 13

    convenience init(rightIcon: UIImage?) {
        self.init()

        let rightIcon = ImageView(image: rightIcon)
        let rightView = UIView(frame: rightIcon.frame)
        rightView.width += padding
        rightView.addSubview(rightIcon)

        self.rightView = rightView
        self.rightViewMode = .always
    }

    override func setupViews() {
        super.setupViews()

        font = R.font.atlasGroteskRegular(size: 18)
        backgroundColor = .white

        tintColor = Color.internationalKleinBlue
        textColor = Color.internationalKleinBlue
        addPaddingLeft(padding)
    }
}
