//
//  TableViewCell.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class TableViewCell: UITableViewCell {
    let disposeBag = DisposeBag()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        backgroundColor = .clear
        layout()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        contentView.size.width = size.width
        layout()
        return contentView.frame.size
    }

    internal func layout() {
        contentView.flex.layout(mode: .adjustHeight)
    }
}
